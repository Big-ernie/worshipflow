-- NON-PRODUCTION: only execute against NEON DEVELOPMENT crmhub_dev.crm_stage.

-- Imported from live CRM catalog, metadata only. No customer data, user accounts or secrets.

-- The single auth.users FK is deliberately deferred until Neon identity migration strategy is tested.

-- The staging schema remains unexposed to Neon Data API, with zero RLS policies and no anonymous grants.

ALTER TABLE crm_stage."organizations" ADD CONSTRAINT "organizations_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."workspace_memberships" ADD CONSTRAINT "workspace_memberships_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."workspace_memberships" ADD CONSTRAINT "workspace_memberships_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."workspace_memberships" ADD CONSTRAINT "workspace_memberships_user_id_fkey" FOREIGN KEY (user_id) REFERENCES crm_stage.profiles(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."role_module_defaults" ADD CONSTRAINT "role_module_defaults_module_key_fkey" FOREIGN KEY (module_key) REFERENCES crm_stage.modules(key) ON DELETE CASCADE;

ALTER TABLE crm_stage."member_module_access" ADD CONSTRAINT "member_module_access_membership_id_fkey" FOREIGN KEY (membership_id) REFERENCES crm_stage.workspace_memberships(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."member_module_access" ADD CONSTRAINT "member_module_access_module_key_fkey" FOREIGN KEY (module_key) REFERENCES crm_stage.modules(key) ON DELETE CASCADE;

ALTER TABLE crm_stage."workspace_invitations" ADD CONSTRAINT "workspace_invitations_invited_by_fkey" FOREIGN KEY (invited_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."workspace_invitations" ADD CONSTRAINT "workspace_invitations_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."support_access_grants" ADD CONSTRAINT "support_access_grants_granted_by_fkey" FOREIGN KEY (granted_by) REFERENCES crm_stage.profiles(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."support_access_grants" ADD CONSTRAINT "support_access_grants_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."support_access_grants" ADD CONSTRAINT "support_access_grants_platform_user_id_fkey" FOREIGN KEY (platform_user_id) REFERENCES crm_stage.profiles(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."platform_subscriptions" ADD CONSTRAINT "platform_subscriptions_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."organization_settings" ADD CONSTRAINT "organization_settings_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."companies" ADD CONSTRAINT "companies_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."companies" ADD CONSTRAINT "companies_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."companies" ADD CONSTRAINT "companies_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."contacts" ADD CONSTRAINT "contacts_company_id_fkey" FOREIGN KEY (company_id) REFERENCES crm_stage.companies(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."contacts" ADD CONSTRAINT "contacts_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."contacts" ADD CONSTRAINT "contacts_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."contacts" ADD CONSTRAINT "contacts_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."products_services" ADD CONSTRAINT "products_services_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."deals" ADD CONSTRAINT "deals_company_id_fkey" FOREIGN KEY (company_id) REFERENCES crm_stage.companies(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."deals" ADD CONSTRAINT "deals_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."deals" ADD CONSTRAINT "deals_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."deals" ADD CONSTRAINT "deals_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."deals" ADD CONSTRAINT "deals_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."deals" ADD CONSTRAINT "deals_product_service_id_fkey" FOREIGN KEY (product_service_id) REFERENCES crm_stage.products_services(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."followups" ADD CONSTRAINT "followups_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."followups" ADD CONSTRAINT "followups_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."followups" ADD CONSTRAINT "followups_deal_id_fkey" FOREIGN KEY (deal_id) REFERENCES crm_stage.deals(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."followups" ADD CONSTRAINT "followups_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."followups" ADD CONSTRAINT "followups_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."quotes" ADD CONSTRAINT "quotes_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."quotes" ADD CONSTRAINT "quotes_deal_id_fkey" FOREIGN KEY (deal_id) REFERENCES crm_stage.deals(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."quotes" ADD CONSTRAINT "quotes_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."activities" ADD CONSTRAINT "activities_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."activities" ADD CONSTRAINT "activities_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."activities" ADD CONSTRAINT "activities_deal_id_fkey" FOREIGN KEY (deal_id) REFERENCES crm_stage.deals(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."activities" ADD CONSTRAINT "activities_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."availability_rules" ADD CONSTRAINT "availability_rules_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."availability_rules" ADD CONSTRAINT "availability_rules_user_id_fkey" FOREIGN KEY (user_id) REFERENCES crm_stage.profiles(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."appointments" ADD CONSTRAINT "appointments_assigned_user_id_fkey" FOREIGN KEY (assigned_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."appointments" ADD CONSTRAINT "appointments_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."appointments" ADD CONSTRAINT "appointments_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES crm_stage.conversations(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."appointments" ADD CONSTRAINT "appointments_created_by_fkey" FOREIGN KEY (created_by) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."appointments" ADD CONSTRAINT "appointments_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."appointments" ADD CONSTRAINT "appointments_product_service_id_fkey" FOREIGN KEY (product_service_id) REFERENCES crm_stage.products_services(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."channel_connections" ADD CONSTRAINT "channel_connections_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."conversations" ADD CONSTRAINT "conversations_assigned_user_id_fkey" FOREIGN KEY (assigned_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."conversations" ADD CONSTRAINT "conversations_channel_connection_id_fkey" FOREIGN KEY (channel_connection_id) REFERENCES crm_stage.channel_connections(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."conversations" ADD CONSTRAINT "conversations_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."conversations" ADD CONSTRAINT "conversations_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES crm_stage.conversations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."messages" ADD CONSTRAINT "messages_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."booking_sessions" ADD CONSTRAINT "booking_sessions_appointment_id_fkey" FOREIGN KEY (appointment_id) REFERENCES crm_stage.appointments(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."booking_sessions" ADD CONSTRAINT "booking_sessions_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."booking_sessions" ADD CONSTRAINT "booking_sessions_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES crm_stage.conversations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."booking_sessions" ADD CONSTRAINT "booking_sessions_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."booking_sessions" ADD CONSTRAINT "booking_sessions_product_service_id_fkey" FOREIGN KEY (product_service_id) REFERENCES crm_stage.products_services(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."audit_log" ADD CONSTRAINT "audit_log_actor_user_id_fkey" FOREIGN KEY (actor_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."audit_log" ADD CONSTRAINT "audit_log_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."organization_ai_settings" ADD CONSTRAINT "organization_ai_settings_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."quote_counters" ADD CONSTRAINT "quote_counters_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES crm_stage.conversations(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_linked_appointment_id_fkey" FOREIGN KEY (linked_appointment_id) REFERENCES crm_stage.appointments(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_linked_deal_id_fkey" FOREIGN KEY (linked_deal_id) REFERENCES crm_stage.deals(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_linked_quote_id_fkey" FOREIGN KEY (linked_quote_id) REFERENCES crm_stage.quotes(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."customer_requests" ADD CONSTRAINT "customer_requests_owner_user_id_fkey" FOREIGN KEY (owner_user_id) REFERENCES crm_stage.profiles(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."request_items" ADD CONSTRAINT "request_items_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."request_items" ADD CONSTRAINT "request_items_product_service_id_fkey" FOREIGN KEY (product_service_id) REFERENCES crm_stage.products_services(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."request_items" ADD CONSTRAINT "request_items_request_id_fkey" FOREIGN KEY (request_id) REFERENCES crm_stage.customer_requests(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."intake_sessions" ADD CONSTRAINT "intake_sessions_contact_id_fkey" FOREIGN KEY (contact_id) REFERENCES crm_stage.contacts(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."intake_sessions" ADD CONSTRAINT "intake_sessions_conversation_id_fkey" FOREIGN KEY (conversation_id) REFERENCES crm_stage.conversations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."intake_sessions" ADD CONSTRAINT "intake_sessions_organization_id_fkey" FOREIGN KEY (organization_id) REFERENCES crm_stage.organizations(id) ON DELETE CASCADE;

ALTER TABLE crm_stage."intake_sessions" ADD CONSTRAINT "intake_sessions_product_service_id_fkey" FOREIGN KEY (product_service_id) REFERENCES crm_stage.products_services(id) ON DELETE SET NULL;

ALTER TABLE crm_stage."intake_sessions" ADD CONSTRAINT "intake_sessions_request_id_fkey" FOREIGN KEY (request_id) REFERENCES crm_stage.customer_requests(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS "idx_activities_contact" ON crm_stage."activities" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "idx_activities_created_by" ON crm_stage."activities" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_activities_deal" ON crm_stage."activities" USING btree (deal_id);

CREATE INDEX IF NOT EXISTS "idx_activities_org" ON crm_stage."activities" USING btree (organization_id, occurred_at DESC);

CREATE INDEX IF NOT EXISTS "idx_appointments_assigned" ON crm_stage."appointments" USING btree (assigned_user_id);

CREATE INDEX IF NOT EXISTS "idx_appointments_contact" ON crm_stage."appointments" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "idx_appointments_conversation" ON crm_stage."appointments" USING btree (conversation_id);

CREATE INDEX IF NOT EXISTS "idx_appointments_created_by" ON crm_stage."appointments" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_appointments_org_start" ON crm_stage."appointments" USING btree (organization_id, start_at);

CREATE INDEX IF NOT EXISTS "idx_appointments_service" ON crm_stage."appointments" USING btree (product_service_id);

CREATE INDEX IF NOT EXISTS "idx_audit_actor" ON crm_stage."audit_log" USING btree (actor_user_id);

CREATE INDEX IF NOT EXISTS "idx_audit_org" ON crm_stage."audit_log" USING btree (organization_id, created_at DESC);

CREATE INDEX IF NOT EXISTS "idx_availability_user" ON crm_stage."availability_rules" USING btree (user_id);

CREATE INDEX IF NOT EXISTS "idx_booking_appointment" ON crm_stage."booking_sessions" USING btree (appointment_id);

CREATE INDEX IF NOT EXISTS "idx_booking_contact" ON crm_stage."booking_sessions" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "idx_booking_conversation" ON crm_stage."booking_sessions" USING btree (conversation_id);

CREATE INDEX IF NOT EXISTS "idx_booking_service" ON crm_stage."booking_sessions" USING btree (product_service_id);

CREATE INDEX IF NOT EXISTS "idx_booking_sessions_org" ON crm_stage."booking_sessions" USING btree (organization_id, expires_at);

CREATE INDEX IF NOT EXISTS "idx_channel_org" ON crm_stage."channel_connections" USING btree (organization_id, channel_type);

CREATE INDEX IF NOT EXISTS "idx_channels_org2" ON crm_stage."channel_connections" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "idx_companies_created_by" ON crm_stage."companies" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_companies_org" ON crm_stage."companies" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "idx_companies_owner" ON crm_stage."companies" USING btree (owner_user_id);

CREATE INDEX IF NOT EXISTS "idx_contacts_company" ON crm_stage."contacts" USING btree (company_id);

CREATE INDEX IF NOT EXISTS "idx_contacts_created_by" ON crm_stage."contacts" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_contacts_org" ON crm_stage."contacts" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "idx_contacts_owner" ON crm_stage."contacts" USING btree (owner_user_id);

CREATE INDEX IF NOT EXISTS "idx_contacts_phone" ON crm_stage."contacts" USING btree (organization_id, phone);

CREATE INDEX IF NOT EXISTS "idx_conversations_assigned" ON crm_stage."conversations" USING btree (assigned_user_id);

CREATE INDEX IF NOT EXISTS "idx_conversations_channel" ON crm_stage."conversations" USING btree (channel_connection_id);

CREATE INDEX IF NOT EXISTS "idx_conversations_contact" ON crm_stage."conversations" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "idx_conversations_org" ON crm_stage."conversations" USING btree (organization_id, last_message_at DESC);

CREATE INDEX IF NOT EXISTS "customer_requests_contact_idx" ON crm_stage."customer_requests" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "customer_requests_conversation_fk_idx" ON crm_stage."customer_requests" USING btree (conversation_id);

CREATE INDEX IF NOT EXISTS "customer_requests_conversation_idx" ON crm_stage."customer_requests" USING btree (organization_id, conversation_id, created_at DESC);

CREATE INDEX IF NOT EXISTS "customer_requests_linked_appointment_idx" ON crm_stage."customer_requests" USING btree (linked_appointment_id);

CREATE INDEX IF NOT EXISTS "customer_requests_linked_deal_idx" ON crm_stage."customer_requests" USING btree (linked_deal_id);

CREATE INDEX IF NOT EXISTS "customer_requests_linked_quote_idx" ON crm_stage."customer_requests" USING btree (linked_quote_id);

CREATE INDEX IF NOT EXISTS "customer_requests_org_status_idx" ON crm_stage."customer_requests" USING btree (organization_id, status, created_at DESC);

CREATE INDEX IF NOT EXISTS "customer_requests_owner_idx" ON crm_stage."customer_requests" USING btree (owner_user_id);

CREATE INDEX IF NOT EXISTS "idx_deals_company" ON crm_stage."deals" USING btree (company_id);

CREATE INDEX IF NOT EXISTS "idx_deals_contact" ON crm_stage."deals" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "idx_deals_created_by" ON crm_stage."deals" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_deals_followup" ON crm_stage."deals" USING btree (organization_id, next_followup_at);

CREATE INDEX IF NOT EXISTS "idx_deals_org_stage" ON crm_stage."deals" USING btree (organization_id, stage);

CREATE INDEX IF NOT EXISTS "idx_deals_owner" ON crm_stage."deals" USING btree (owner_user_id);

CREATE INDEX IF NOT EXISTS "idx_deals_service" ON crm_stage."deals" USING btree (product_service_id);

CREATE INDEX IF NOT EXISTS "idx_followups_contact" ON crm_stage."followups" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "idx_followups_created_by" ON crm_stage."followups" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_followups_deal" ON crm_stage."followups" USING btree (deal_id);

CREATE INDEX IF NOT EXISTS "idx_followups_org_due" ON crm_stage."followups" USING btree (organization_id, status, due_at);

CREATE INDEX IF NOT EXISTS "idx_followups_owner" ON crm_stage."followups" USING btree (owner_user_id);

CREATE INDEX IF NOT EXISTS "intake_sessions_active_idx" ON crm_stage."intake_sessions" USING btree (organization_id, conversation_id, expires_at DESC);

CREATE INDEX IF NOT EXISTS "intake_sessions_contact_idx" ON crm_stage."intake_sessions" USING btree (contact_id);

CREATE INDEX IF NOT EXISTS "intake_sessions_conversation_idx" ON crm_stage."intake_sessions" USING btree (conversation_id);

CREATE INDEX IF NOT EXISTS "intake_sessions_product_idx" ON crm_stage."intake_sessions" USING btree (product_service_id);

CREATE INDEX IF NOT EXISTS "intake_sessions_request_idx" ON crm_stage."intake_sessions" USING btree (request_id);

CREATE INDEX IF NOT EXISTS "idx_member_access_module" ON crm_stage."member_module_access" USING btree (module_key);

CREATE INDEX IF NOT EXISTS "idx_messages_conversation" ON crm_stage."messages" USING btree (conversation_id, occurred_at);

CREATE INDEX IF NOT EXISTS "idx_messages_org" ON crm_stage."messages" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "messages_conversation_time_idx" ON crm_stage."messages" USING btree (organization_id, conversation_id, occurred_at);

CREATE UNIQUE INDEX IF NOT EXISTS "messages_org_provider_message_uidx" ON crm_stage."messages" USING btree (organization_id, provider_message_id) WHERE (provider_message_id IS NOT NULL);

CREATE INDEX IF NOT EXISTS "idx_organizations_created_by" ON crm_stage."organizations" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_products_org" ON crm_stage."products_services" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "idx_quotes_created_by" ON crm_stage."quotes" USING btree (created_by);

CREATE INDEX IF NOT EXISTS "idx_quotes_deal" ON crm_stage."quotes" USING btree (deal_id);

CREATE INDEX IF NOT EXISTS "idx_quotes_org" ON crm_stage."quotes" USING btree (organization_id, status);

CREATE INDEX IF NOT EXISTS "request_items_org_idx" ON crm_stage."request_items" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "request_items_product_idx" ON crm_stage."request_items" USING btree (product_service_id);

CREATE INDEX IF NOT EXISTS "request_items_request_idx" ON crm_stage."request_items" USING btree (request_id);

CREATE INDEX IF NOT EXISTS "idx_role_defaults_module" ON crm_stage."role_module_defaults" USING btree (module_key);

CREATE INDEX IF NOT EXISTS "idx_support_granted_by" ON crm_stage."support_access_grants" USING btree (granted_by);

CREATE INDEX IF NOT EXISTS "idx_support_org" ON crm_stage."support_access_grants" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "idx_support_platform_user" ON crm_stage."support_access_grants" USING btree (platform_user_id);

CREATE INDEX IF NOT EXISTS "idx_invites_invited_by" ON crm_stage."workspace_invitations" USING btree (invited_by);

CREATE INDEX IF NOT EXISTS "idx_invites_org" ON crm_stage."workspace_invitations" USING btree (organization_id);

CREATE INDEX IF NOT EXISTS "idx_memberships_invited_by" ON crm_stage."workspace_memberships" USING btree (invited_by);

CREATE INDEX IF NOT EXISTS "idx_memberships_user" ON crm_stage."workspace_memberships" USING btree (user_id);
