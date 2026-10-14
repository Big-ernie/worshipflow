-- Neon dev ONLY, empty CRM schema staged from current Supabase catalog (2026-10-13).

-- No customer data, user IDs, RLS policy transfer, Auth migration, functions, triggers, indexes or FKs.

-- Non-exposed schema, not suitable as production backend.

CREATE SCHEMA IF NOT EXISTS crm_stage;

REVOKE ALL ON SCHEMA crm_stage FROM PUBLIC;

CREATE SEQUENCE IF NOT EXISTS crm_stage.audit_log_id_seq;

CREATE TABLE IF NOT EXISTS crm_stage."activities" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "deal_id" uuid,
  "contact_id" uuid,
  "activity_type" text NOT NULL,
  "summary" text NOT NULL,
  "occurred_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "activities_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."activities" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."activities" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."appointments" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "contact_id" uuid,
  "product_service_id" uuid,
  "assigned_user_id" uuid,
  "source" text DEFAULT 'manual'::text NOT NULL,
  "status" text DEFAULT 'requested'::text NOT NULL,
  "start_at" timestamp with time zone,
  "end_at" timestamp with time zone,
  "customer_name" text,
  "customer_phone" text,
  "customer_email" text,
  "notes" text,
  "booking_reference" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "conversation_id" uuid,
  CONSTRAINT "appointments_booking_reference_key" UNIQUE (booking_reference),
  CONSTRAINT "appointments_pkey" PRIMARY KEY (id),
  CONSTRAINT "appointments_source_check" CHECK ((source = ANY (ARRAY['manual'::text, 'website'::text, 'whatsapp'::text, 'email'::text, 'phone'::text, 'api'::text]))),
  CONSTRAINT "appointments_status_check" CHECK ((status = ANY (ARRAY['requested'::text, 'pending'::text, 'confirmed'::text, 'completed'::text, 'cancelled'::text, 'no_show'::text])))
);

ALTER TABLE crm_stage."appointments" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."appointments" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."audit_log" (
  "id" bigint DEFAULT nextval('crm_stage.audit_log_id_seq'::regclass) NOT NULL,
  "organization_id" uuid,
  "actor_user_id" uuid,
  "action" text NOT NULL,
  "entity_type" text,
  "entity_id" uuid,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "audit_log_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."audit_log" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."audit_log" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."availability_rules" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "user_id" uuid,
  "weekday" smallint NOT NULL,
  "start_time" time without time zone NOT NULL,
  "end_time" time without time zone NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  CONSTRAINT "availability_rules_organization_id_user_id_weekday_start_ti_key" UNIQUE (organization_id, user_id, weekday, start_time, end_time),
  CONSTRAINT "availability_rules_pkey" PRIMARY KEY (id),
  CONSTRAINT "availability_rules_weekday_check" CHECK (((weekday >= 0) AND (weekday <= 6)))
);

ALTER TABLE crm_stage."availability_rules" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."availability_rules" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."booking_sessions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "conversation_id" uuid,
  "contact_id" uuid,
  "state" text DEFAULT 'start'::text NOT NULL,
  "product_service_id" uuid,
  "requested_date" date,
  "requested_time" time without time zone,
  "appointment_id" uuid,
  "context" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '02:00:00'::interval) NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "booking_sessions_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."booking_sessions" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."booking_sessions" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."channel_connections" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "channel_type" text NOT NULL,
  "provider" text,
  "display_name" text,
  "external_account_id" text,
  "phone_number" text,
  "status" text DEFAULT 'disconnected'::text NOT NULL,
  "secret_ref" text,
  "configuration" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "channel_connections_channel_type_check" CHECK ((channel_type = ANY (ARRAY['whatsapp'::text, 'email'::text, 'sms'::text]))),
  CONSTRAINT "channel_connections_pkey" PRIMARY KEY (id),
  CONSTRAINT "channel_connections_status_check" CHECK ((status = ANY (ARRAY['disconnected'::text, 'pending'::text, 'connected'::text, 'error'::text])))
);

ALTER TABLE crm_stage."channel_connections" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."channel_connections" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."companies" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "name" text NOT NULL,
  "industry" text,
  "website" text,
  "email" text,
  "phone" text,
  "location" text,
  "notes" text,
  "owner_user_id" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "companies_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."companies" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."companies" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."contacts" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "company_id" uuid,
  "first_name" text NOT NULL,
  "last_name" text,
  "job_title" text,
  "email" text,
  "phone" text,
  "whatsapp" text,
  "preferred_channel" text,
  "notes" text,
  "owner_user_id" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "contacts_pkey" PRIMARY KEY (id),
  CONSTRAINT "contacts_preferred_channel_check" CHECK ((preferred_channel = ANY (ARRAY['WhatsApp'::text, 'Email'::text, 'Phone'::text, 'Other'::text])))
);

ALTER TABLE crm_stage."contacts" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."contacts" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."conversations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "channel_connection_id" uuid,
  "contact_id" uuid,
  "external_thread_id" text,
  "status" text DEFAULT 'open'::text NOT NULL,
  "last_message_at" timestamp with time zone,
  "assigned_user_id" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "last_inbound_at" timestamp with time zone,
  "last_outbound_at" timestamp with time zone,
  CONSTRAINT "conversations_pkey" PRIMARY KEY (id),
  CONSTRAINT "conversations_status_check" CHECK ((status = ANY (ARRAY['open'::text, 'pending'::text, 'closed'::text])))
);

ALTER TABLE crm_stage."conversations" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."conversations" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."customer_requests" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "contact_id" uuid,
  "conversation_id" uuid,
  "request_number" text NOT NULL,
  "request_type" text DEFAULT 'enquiry'::text NOT NULL,
  "source" text DEFAULT 'whatsapp'::text NOT NULL,
  "status" text DEFAULT 'new'::text NOT NULL,
  "title" text,
  "notes" text,
  "total" numeric DEFAULT 0 NOT NULL,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "linked_deal_id" uuid,
  "linked_quote_id" uuid,
  "linked_appointment_id" uuid,
  "owner_user_id" uuid,
  "next_action" text,
  "next_followup_at" timestamp with time zone,
  "metadata" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "customer_requests_organization_id_request_number_key" UNIQUE (organization_id, request_number),
  CONSTRAINT "customer_requests_pkey" PRIMARY KEY (id),
  CONSTRAINT "customer_requests_status_check" CHECK ((status = ANY (ARRAY['new'::text, 'collecting'::text, 'ready'::text, 'in_progress'::text, 'waiting_customer'::text, 'won'::text, 'completed'::text, 'cancelled'::text, 'lost'::text]))),
  CONSTRAINT "customer_requests_type_check" CHECK ((request_type = ANY (ARRAY['enquiry'::text, 'quote'::text, 'order'::text, 'booking'::text, 'support'::text])))
);

ALTER TABLE crm_stage."customer_requests" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."customer_requests" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."deals" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "title" text NOT NULL,
  "company_id" uuid,
  "contact_id" uuid,
  "product_service_id" uuid,
  "stage" text DEFAULT 'New Enquiry'::text NOT NULL,
  "priority" text DEFAULT 'Medium'::text NOT NULL,
  "amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "lead_source" text,
  "next_action" text,
  "next_followup_at" timestamp with time zone,
  "expected_close_date" date,
  "won_at" timestamp with time zone,
  "lost_at" timestamp with time zone,
  "lost_reason" text,
  "owner_user_id" uuid,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "deals_amount_check" CHECK ((amount >= (0)::numeric)),
  CONSTRAINT "deals_pkey" PRIMARY KEY (id),
  CONSTRAINT "deals_priority_check" CHECK ((priority = ANY (ARRAY['High'::text, 'Medium'::text, 'Low'::text])))
);

ALTER TABLE crm_stage."deals" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."deals" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."followups" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "deal_id" uuid,
  "contact_id" uuid,
  "subject" text NOT NULL,
  "channel" text,
  "due_at" timestamp with time zone NOT NULL,
  "status" text DEFAULT 'Pending'::text NOT NULL,
  "priority" text DEFAULT 'Medium'::text NOT NULL,
  "notes" text,
  "owner_user_id" uuid,
  "completed_at" timestamp with time zone,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "followups_channel_check" CHECK ((channel = ANY (ARRAY['WhatsApp'::text, 'Email'::text, 'Phone'::text, 'Meeting'::text, 'Other'::text]))),
  CONSTRAINT "followups_pkey" PRIMARY KEY (id),
  CONSTRAINT "followups_priority_check" CHECK ((priority = ANY (ARRAY['High'::text, 'Medium'::text, 'Low'::text]))),
  CONSTRAINT "followups_status_check" CHECK ((status = ANY (ARRAY['Pending'::text, 'Done'::text, 'Skipped'::text])))
);

ALTER TABLE crm_stage."followups" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."followups" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."intake_sessions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "contact_id" uuid,
  "request_type" text NOT NULL,
  "state" text DEFAULT 'start'::text NOT NULL,
  "product_service_id" uuid,
  "request_id" uuid,
  "context" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "expires_at" timestamp with time zone DEFAULT (now() + '02:00:00'::interval) NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "intake_sessions_pkey" PRIMARY KEY (id),
  CONSTRAINT "intake_sessions_type_check" CHECK ((request_type = ANY (ARRAY['quote'::text, 'order'::text, 'enquiry'::text, 'support'::text])))
);

ALTER TABLE crm_stage."intake_sessions" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."intake_sessions" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."member_module_access" (
  "membership_id" uuid NOT NULL,
  "module_key" text NOT NULL,
  "access_level" text NOT NULL,
  CONSTRAINT "member_module_access_access_level_check" CHECK ((access_level = ANY (ARRAY['none'::text, 'view'::text, 'edit'::text, 'admin'::text]))),
  CONSTRAINT "member_module_access_pkey" PRIMARY KEY (membership_id, module_key)
);

ALTER TABLE crm_stage."member_module_access" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."member_module_access" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."messages" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "conversation_id" uuid NOT NULL,
  "direction" text NOT NULL,
  "provider_message_id" text,
  "message_type" text DEFAULT 'text'::text NOT NULL,
  "body" text,
  "payload" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "status" text,
  "occurred_at" timestamp with time zone DEFAULT now() NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "messages_direction_check" CHECK ((direction = ANY (ARRAY['inbound'::text, 'outbound'::text]))),
  CONSTRAINT "messages_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."messages" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."messages" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."modules" (
  "key" text NOT NULL,
  "label" text NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  CONSTRAINT "modules_pkey" PRIMARY KEY (key)
);

ALTER TABLE crm_stage."modules" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."modules" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."organization_ai_settings" (
  "organization_id" uuid NOT NULL,
  "allow_ai_analysis" boolean DEFAULT true NOT NULL,
  "allow_training_export" boolean DEFAULT false NOT NULL,
  "pii_redaction_required" boolean DEFAULT true NOT NULL,
  "cross_tenant_raw_data_use" boolean DEFAULT false NOT NULL,
  "retention_days" integer DEFAULT 365 NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "organization_ai_settings_cross_tenant_raw_data_use_check" CHECK ((cross_tenant_raw_data_use = false)),
  CONSTRAINT "organization_ai_settings_pkey" PRIMARY KEY (organization_id),
  CONSTRAINT "organization_ai_settings_retention_days_check" CHECK (((retention_days >= 30) AND (retention_days <= 3650)))
);

ALTER TABLE crm_stage."organization_ai_settings" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."organization_ai_settings" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."organization_settings" (
  "organization_id" uuid NOT NULL,
  "logo_url" text,
  "primary_color" text,
  "accent_color" text,
  "lead_assignment_mode" text DEFAULT 'manual'::text NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "dashboard_preset" text DEFAULT 'general'::text NOT NULL,
  "dashboard_config" jsonb DEFAULT '{"widgets": ["attention", "kpis", "inbox", "pipeline", "followups", "appointments"]}'::jsonb NOT NULL,
  "dashboard_config_version" integer DEFAULT 1 NOT NULL,
  "business_template" text DEFAULT 'general'::text NOT NULL,
  "template_applied_at" timestamp with time zone,
  CONSTRAINT "organization_settings_business_template_check" CHECK ((business_template = ANY (ARRAY['general'::text, 'b2b_quotes'::text, 'retail_orders'::text, 'services_bookings'::text, 'restaurant_food'::text, 'beauty_wellness'::text, 'consulting'::text]))),
  CONSTRAINT "organization_settings_dashboard_config_object_check" CHECK ((jsonb_typeof(dashboard_config) = 'object'::text)),
  CONSTRAINT "organization_settings_dashboard_preset_check" CHECK ((dashboard_preset = ANY (ARRAY['general'::text, 'sales_quotes'::text, 'retail_orders'::text, 'services_bookings'::text]))),
  CONSTRAINT "organization_settings_lead_assignment_mode_check" CHECK ((lead_assignment_mode = ANY (ARRAY['manual'::text, 'round_robin'::text]))),
  CONSTRAINT "organization_settings_pkey" PRIMARY KEY (organization_id)
);

ALTER TABLE crm_stage."organization_settings" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."organization_settings" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."organizations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "name" text NOT NULL,
  "slug" text NOT NULL,
  "workspace_type" text DEFAULT 'customer'::text NOT NULL,
  "industry" text,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "timezone" text DEFAULT 'Africa/Accra'::text NOT NULL,
  "status" text DEFAULT 'active'::text NOT NULL,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "organizations_pkey" PRIMARY KEY (id),
  CONSTRAINT "organizations_slug_key" UNIQUE (slug),
  CONSTRAINT "organizations_status_check" CHECK ((status = ANY (ARRAY['trial'::text, 'active'::text, 'paused'::text, 'cancelled'::text]))),
  CONSTRAINT "organizations_workspace_type_check" CHECK ((workspace_type = ANY (ARRAY['customer'::text, 'internal'::text, 'sandbox'::text])))
);

ALTER TABLE crm_stage."organizations" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."organizations" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."plan_catalog" (
  "plan_name" text NOT NULL,
  "display_name" text NOT NULL,
  "monthly_amount" numeric(12,2) DEFAULT 0 NOT NULL,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "max_users" integer NOT NULL,
  "max_contacts" integer NOT NULL,
  "max_deals" integer NOT NULL,
  "max_whatsapp_connections" integer NOT NULL,
  "features" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  CONSTRAINT "plan_catalog_pkey" PRIMARY KEY (plan_name)
);

ALTER TABLE crm_stage."plan_catalog" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."plan_catalog" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."platform_subscriptions" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "plan_name" text DEFAULT 'trial'::text NOT NULL,
  "status" text DEFAULT 'trial'::text NOT NULL,
  "monthly_amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "trial_ends_at" timestamp with time zone,
  "renewal_at" timestamp with time zone,
  "notes" text,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "platform_subscriptions_organization_id_key" UNIQUE (organization_id),
  CONSTRAINT "platform_subscriptions_pkey" PRIMARY KEY (id),
  CONSTRAINT "platform_subscriptions_status_check" CHECK ((status = ANY (ARRAY['trial'::text, 'active'::text, 'past_due'::text, 'paused'::text, 'cancelled'::text])))
);

ALTER TABLE crm_stage."platform_subscriptions" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."platform_subscriptions" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."products_services" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "name" text NOT NULL,
  "category" text,
  "description" text,
  "sku" text,
  "price" numeric(14,2),
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "is_bookable" boolean DEFAULT false NOT NULL,
  "duration_minutes" integer,
  "requires_deposit" boolean DEFAULT false NOT NULL,
  "deposit_amount" numeric(14,2),
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  "item_type" text DEFAULT 'service'::text NOT NULL,
  "is_orderable" boolean DEFAULT false NOT NULL,
  "inventory_tracking" boolean DEFAULT false NOT NULL,
  "stock_quantity" numeric,
  "low_stock_threshold" numeric,
  "image_url" text,
  "whatsapp_catalog_enabled" boolean DEFAULT false NOT NULL,
  "sort_order" integer DEFAULT 0 NOT NULL,
  CONSTRAINT "products_services_item_type_check" CHECK ((item_type = ANY (ARRAY['product'::text, 'service'::text, 'hybrid'::text]))),
  CONSTRAINT "products_services_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."products_services" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."products_services" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."profiles" (
  "id" uuid NOT NULL,
  "email" text,
  "full_name" text,
  "is_platform_staff" boolean DEFAULT false NOT NULL,
  "is_platform_owner" boolean DEFAULT false NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "profiles_email_key" UNIQUE (email),
  CONSTRAINT "profiles_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."profiles" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."profiles" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."quote_counters" (
  "organization_id" uuid NOT NULL,
  "quote_year" integer NOT NULL,
  "last_number" integer DEFAULT 0 NOT NULL,
  CONSTRAINT "quote_counters_pkey" PRIMARY KEY (organization_id, quote_year)
);

ALTER TABLE crm_stage."quote_counters" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."quote_counters" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."quotes" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "deal_id" uuid NOT NULL,
  "quote_number" text NOT NULL,
  "amount" numeric(14,2) DEFAULT 0 NOT NULL,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "status" text DEFAULT 'Draft'::text NOT NULL,
  "sent_at" timestamp with time zone,
  "valid_until" date,
  "document_path" text,
  "notes" text,
  "created_by" uuid,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  "updated_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "quotes_organization_id_quote_number_key" UNIQUE (organization_id, quote_number),
  CONSTRAINT "quotes_pkey" PRIMARY KEY (id),
  CONSTRAINT "quotes_status_check" CHECK ((status = ANY (ARRAY['Draft'::text, 'Sent'::text, 'Accepted'::text, 'Rejected'::text, 'Expired'::text])))
);

ALTER TABLE crm_stage."quotes" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."quotes" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."request_items" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "request_id" uuid NOT NULL,
  "product_service_id" uuid,
  "item_name" text NOT NULL,
  "quantity" numeric DEFAULT 1 NOT NULL,
  "unit_price" numeric,
  "currency" text DEFAULT 'GHS'::text NOT NULL,
  "notes" text,
  "options" jsonb DEFAULT '{}'::jsonb NOT NULL,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "request_items_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."request_items" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."request_items" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."role_module_defaults" (
  "role" text NOT NULL,
  "module_key" text NOT NULL,
  "access_level" text NOT NULL,
  CONSTRAINT "role_module_defaults_access_level_check" CHECK ((access_level = ANY (ARRAY['none'::text, 'view'::text, 'edit'::text, 'admin'::text]))),
  CONSTRAINT "role_module_defaults_pkey" PRIMARY KEY (role, module_key),
  CONSTRAINT "role_module_defaults_role_check" CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'manager'::text, 'sales'::text, 'support'::text, 'viewer'::text])))
);

ALTER TABLE crm_stage."role_module_defaults" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."role_module_defaults" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."support_access_grants" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "platform_user_id" uuid NOT NULL,
  "granted_by" uuid NOT NULL,
  "reason" text,
  "expires_at" timestamp with time zone NOT NULL,
  "revoked_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "support_access_grants_pkey" PRIMARY KEY (id)
);

ALTER TABLE crm_stage."support_access_grants" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."support_access_grants" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."workspace_invitations" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "email" text NOT NULL,
  "role" text NOT NULL,
  "token" text NOT NULL,
  "invited_by" uuid,
  "expires_at" timestamp with time zone NOT NULL,
  "accepted_at" timestamp with time zone,
  "created_at" timestamp with time zone DEFAULT now() NOT NULL,
  CONSTRAINT "workspace_invitations_pkey" PRIMARY KEY (id),
  CONSTRAINT "workspace_invitations_role_check" CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'manager'::text, 'sales'::text, 'support'::text, 'viewer'::text]))),
  CONSTRAINT "workspace_invitations_token_key" UNIQUE (token)
);

ALTER TABLE crm_stage."workspace_invitations" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."workspace_invitations" FROM PUBLIC;

CREATE TABLE IF NOT EXISTS crm_stage."workspace_memberships" (
  "id" uuid DEFAULT gen_random_uuid() NOT NULL,
  "organization_id" uuid NOT NULL,
  "user_id" uuid NOT NULL,
  "role" text DEFAULT 'viewer'::text NOT NULL,
  "active" boolean DEFAULT true NOT NULL,
  "joined_at" timestamp with time zone DEFAULT now() NOT NULL,
  "invited_by" uuid,
  CONSTRAINT "workspace_memberships_organization_id_user_id_key" UNIQUE (organization_id, user_id),
  CONSTRAINT "workspace_memberships_pkey" PRIMARY KEY (id),
  CONSTRAINT "workspace_memberships_role_check" CHECK ((role = ANY (ARRAY['owner'::text, 'admin'::text, 'manager'::text, 'sales'::text, 'support'::text, 'viewer'::text])))
);

ALTER TABLE crm_stage."workspace_memberships" ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON crm_stage."workspace_memberships" FROM PUBLIC;
