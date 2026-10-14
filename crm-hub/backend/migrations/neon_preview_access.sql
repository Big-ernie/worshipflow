-- Development-only Neon staging security, never apply to the live Supabase project.
-- Created for isolated login/workspace/deal/contact smoke tests, NOT full CRM production.
-- All public identities and data in this schema are test-only. Passwords do not migrate.
-- Row isolation is enforced by Neon-issued JWT auth.uid() and owner membership.
-- Public/anonymous cannot use this schema; no customer data is imported.

INSERT INTO crm_stage.modules (key,label,sort_order) VALUES ('dashboard','Dashboard',10),
('contacts','Contacts',20),
('companies','Companies',30),
('deals','Deals / Pipeline',40),
('quotes','Quotes',50),
('followups','Follow-ups',60),
('appointments','Appointments',70),
('whatsapp','WhatsApp',80),
('products_services','Products & Services',90),
('reports','Reports',100),
('exports','Exports',110),
('team','Team & Access',120),
('settings','Settings',130) ON CONFLICT (key) DO NOTHING;

CREATE OR REPLACE FUNCTION crm_stage.preview_owns_workspace(p_org uuid)
RETURNS boolean LANGUAGE sql STABLE SECURITY DEFINER SET search_path = pg_catalog AS $f$
 SELECT (SELECT auth.uid()) IS NOT NULL
  AND EXISTS (
   SELECT 1 FROM crm_stage.workspace_memberships m
   JOIN crm_stage.organizations o ON o.id=m.organization_id
   WHERE m.organization_id=p_org
     AND m.user_id=(SELECT auth.uid()) AND m.active=true AND m.role='owner'
     AND o.status IN ('trial','active')
  );
$f$;

REVOKE ALL ON FUNCTION crm_stage.preview_owns_workspace(uuid) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION crm_stage.preview_owns_workspace(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION crm_stage.preview_bootstrap_profile(p_full_name text DEFAULT NULL)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $f$
DECLARE v_user uuid := auth.uid();
BEGIN
 IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication is required' USING ERRCODE='28000'; END IF;
 IF p_full_name IS NOT NULL AND length(trim(p_full_name)) > 160 THEN RAISE EXCEPTION 'Name too long'; END IF;
 INSERT INTO crm_stage.profiles(id,full_name,is_platform_staff,is_platform_owner)
 VALUES (v_user,NULLIF(trim(p_full_name),''),false,false)
 ON CONFLICT(id) DO NOTHING;
 RETURN v_user;
END;
$f$;

REVOKE ALL ON FUNCTION crm_stage.preview_bootstrap_profile(text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION crm_stage.preview_bootstrap_profile(text) TO authenticated;

CREATE OR REPLACE FUNCTION crm_stage.preview_create_workspace(
 p_name text, p_industry text DEFAULT NULL, p_business_template text DEFAULT 'general')
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path = pg_catalog AS $f$
DECLARE
 v_user uuid := auth.uid();
 v_org uuid;
 v_member uuid;
 v_name text := trim(p_name);
 v_slug text;
 v_template text := coalesce(p_business_template,'general');
BEGIN
 IF v_user IS NULL THEN RAISE EXCEPTION 'Authentication required' USING ERRCODE='28000'; END IF;
 IF length(v_name) < 2 OR length(v_name)>100 THEN RAISE EXCEPTION 'Workspace name must be 2 to 100 characters'; END IF;
 IF p_industry IS NOT NULL AND length(p_industry)>100 THEN RAISE EXCEPTION 'Industry too long'; END IF;
 IF v_template NOT IN ('general','b2b_quotes','retail_orders','services_bookings','restaurant_food','beauty_wellness','consulting')
 THEN RAISE EXCEPTION 'Unsupported template'; END IF;
 IF (SELECT count(*) FROM crm_stage.organizations WHERE created_by=v_user)>=3 THEN
  RAISE EXCEPTION 'Development workspace limit reached'; END IF;
 PERFORM crm_stage.preview_bootstrap_profile(NULL);
 v_slug:=substring(regexp_replace(lower(v_name),'[^a-z0-9]+','-','g') from 1 for 48)
   ||'-'||substring(replace(gen_random_uuid()::text,'-','') from 1 for 10);
 INSERT INTO crm_stage.organizations (name,slug,workspace_type,industry,currency,timezone,status,created_by)
 VALUES(v_name,v_slug,'customer',NULLIF(trim(coalesce(p_industry,'')),''),'GHS','Africa/Accra','trial',v_user)
 RETURNING id INTO v_org;
 INSERT INTO crm_stage.workspace_memberships(organization_id,user_id,role,active) VALUES(v_org,v_user,'owner',true)
 RETURNING id INTO v_member;
 INSERT INTO crm_stage.organization_settings(organization_id,business_template,template_applied_at)
 VALUES(v_org,v_template,now());
 INSERT INTO crm_stage.platform_subscriptions(organization_id,plan_name,status,monthly_amount,currency)
 VALUES(v_org,'trial','trial',0,'GHS');
 INSERT INTO crm_stage.member_module_access(membership_id,module_key,access_level)
 SELECT v_member,m.key,'admin' FROM crm_stage.modules m;
 RETURN v_org;
END;
$f$;

REVOKE ALL ON FUNCTION crm_stage.preview_create_workspace(text,text,text) FROM PUBLIC;

GRANT EXECUTE ON FUNCTION crm_stage.preview_create_workspace(text,text,text) TO authenticated;

CREATE POLICY preview_profiles_select ON crm_stage.profiles FOR SELECT TO authenticated
 USING (id=(SELECT auth.uid()));

CREATE POLICY preview_memberships_select ON crm_stage.workspace_memberships FOR SELECT TO authenticated
 USING (user_id=(SELECT auth.uid()) AND active=true);

CREATE POLICY preview_orgs_select ON crm_stage.organizations FOR SELECT TO authenticated
 USING (crm_stage.preview_owns_workspace(id));

CREATE POLICY preview_modules_select ON crm_stage.modules FOR SELECT TO authenticated USING (true);

CREATE POLICY preview_member_access_select ON crm_stage.member_module_access FOR SELECT TO authenticated
 USING (EXISTS (SELECT 1 FROM crm_stage.workspace_memberships m
 WHERE m.id=membership_id AND m.user_id=(SELECT auth.uid()) AND m.active=true));

CREATE POLICY preview_settings_select ON crm_stage.organization_settings FOR SELECT TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_subscriptions_select ON crm_stage.platform_subscriptions FOR SELECT TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_deals_select ON crm_stage.deals FOR SELECT TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_deals_insert ON crm_stage.deals FOR INSERT TO authenticated
 WITH CHECK (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_deals_update ON crm_stage.deals FOR UPDATE TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id))
 WITH CHECK (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_deals_delete ON crm_stage.deals FOR DELETE TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_contacts_select ON crm_stage.contacts FOR SELECT TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_contacts_insert ON crm_stage.contacts FOR INSERT TO authenticated
 WITH CHECK (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_contacts_update ON crm_stage.contacts FOR UPDATE TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id))
 WITH CHECK (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_contacts_delete ON crm_stage.contacts FOR DELETE TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_products_select ON crm_stage.products_services FOR SELECT TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_products_insert ON crm_stage.products_services FOR INSERT TO authenticated
 WITH CHECK (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_products_update ON crm_stage.products_services FOR UPDATE TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id))
 WITH CHECK (crm_stage.preview_owns_workspace(organization_id));

CREATE POLICY preview_products_delete ON crm_stage.products_services FOR DELETE TO authenticated
 USING (crm_stage.preview_owns_workspace(organization_id));

-- Explicit permissions are granted only AFTER enabling ownership-scoped RLS policies.
GRANT USAGE ON SCHEMA crm_stage TO authenticated;

GRANT SELECT ON crm_stage.profiles,crm_stage.organizations,crm_stage.workspace_memberships,
 crm_stage.modules,crm_stage.member_module_access,crm_stage.organization_settings,
 crm_stage.platform_subscriptions,crm_stage.deals,crm_stage.contacts,crm_stage.products_services
 TO authenticated;

GRANT INSERT(organization_id,title,stage,amount,currency,next_action)
 ON crm_stage.deals TO authenticated;

GRANT UPDATE(title,stage,amount,next_action,next_followup_at)
 ON crm_stage.deals TO authenticated;

GRANT DELETE ON crm_stage.deals TO authenticated;

GRANT INSERT(organization_id,first_name,last_name,email,phone,notes)
 ON crm_stage.contacts TO authenticated;

GRANT UPDATE(first_name,last_name,email,phone,notes)
 ON crm_stage.contacts TO authenticated;

GRANT DELETE ON crm_stage.contacts TO authenticated;

GRANT INSERT(organization_id,name,category,price,currency,is_bookable)
 ON crm_stage.products_services TO authenticated;

GRANT UPDATE(name,category,price,is_bookable)
 ON crm_stage.products_services TO authenticated;

GRANT DELETE ON crm_stage.products_services TO authenticated;

-- Explicitly deny unverified anonymous access, including all future stages.
REVOKE ALL ON SCHEMA crm_stage FROM anonymous;
