-- Neon Data API `authenticated` role may not have USAGE on Neon-owned auth schema.
-- Proxy auth.uid() through an owner-owned, locked-down SECURITY DEFINER helper.
-- Returns ONLY the current signed JWT's own user ID. No arbitrary target is accepted.
CREATE OR REPLACE FUNCTION crm_stage.preview_identity()
RETURNS uuid LANGUAGE sql STABLE SECURITY DEFINER
SET search_path = pg_catalog AS $f$
 SELECT auth.uid();
$f$;

REVOKE ALL ON FUNCTION crm_stage.preview_identity() FROM PUBLIC;

GRANT EXECUTE ON FUNCTION crm_stage.preview_identity() TO authenticated;

ALTER POLICY preview_profiles_select ON crm_stage.profiles TO authenticated
 USING (id=(SELECT crm_stage.preview_identity()));

ALTER POLICY preview_memberships_select ON crm_stage.workspace_memberships TO authenticated
 USING (user_id=(SELECT crm_stage.preview_identity()) AND active=true);

ALTER POLICY preview_member_access_select ON crm_stage.member_module_access TO authenticated
 USING (EXISTS (SELECT 1 FROM crm_stage.workspace_memberships m
 WHERE m.id=membership_id AND m.user_id=(SELECT crm_stage.preview_identity()) AND m.active=true));
