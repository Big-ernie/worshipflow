-- Company-specific dashboard configuration for Big Ernie CRM Hub.
-- Uses organization_settings so the dashboard follows the tenant/workspace
-- and existing settings RLS controls who can modify it.

begin;

alter table public.organization_settings
  add column if not exists dashboard_preset text not null default 'general',
  add column if not exists dashboard_config jsonb not null default '{"widgets":["attention","kpis","inbox","pipeline","followups","appointments"]}'::jsonb,
  add column if not exists dashboard_config_version integer not null default 1;

do $$ begin
  if not exists (
    select 1 from pg_constraint where conname='organization_settings_dashboard_preset_check'
  ) then
    alter table public.organization_settings
      add constraint organization_settings_dashboard_preset_check
      check (dashboard_preset in ('general','sales_quotes','retail_orders','services_bookings'));
  end if;

  if not exists (
    select 1 from pg_constraint where conname='organization_settings_dashboard_config_object_check'
  ) then
    alter table public.organization_settings
      add constraint organization_settings_dashboard_config_object_check
      check (jsonb_typeof(dashboard_config)='object');
  end if;
end $$;

commit;
