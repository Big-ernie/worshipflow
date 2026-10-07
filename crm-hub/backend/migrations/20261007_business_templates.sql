-- Big Ernie CRM Hub: business template selection.
-- Templates only configure workspace UI defaults; they never delete or seed CRM records.

begin;

alter table public.organization_settings
  add column if not exists business_template text not null default 'general',
  add column if not exists template_applied_at timestamptz;

do $$ begin
  if not exists (
    select 1 from pg_constraint where conname='organization_settings_business_template_check'
  ) then
    alter table public.organization_settings
      add constraint organization_settings_business_template_check
      check (business_template in (
        'general',
        'b2b_quotes',
        'retail_orders',
        'services_bookings',
        'restaurant_food',
        'beauty_wellness',
        'consulting'
      ));
  end if;
end $$;

commit;


-- Atomically create a workspace and apply its selected template.
create or replace function public.create_workspace_template_server(
  p_user uuid,
  p_name text,
  p_slug text default null,
  p_industry text default null,
  p_currency text default 'GHS',
  p_timezone text default 'Africa/Accra',
  p_business_template text default 'general'
)
returns uuid
language plpgsql
security definer
set search_path='public'
as $$
declare
  oid uuid;
  v_preset text;
  v_widgets jsonb;
begin
  case p_business_template
    when 'general' then
      v_preset := 'general';
      v_widgets := '["attention","kpis","inbox","pipeline","followups","appointments"]'::jsonb;
    when 'b2b_quotes' then
      v_preset := 'sales_quotes';
      v_widgets := '["attention","requests","pipeline","followups","kpis","inbox"]'::jsonb;
    when 'retail_orders' then
      v_preset := 'retail_orders';
      v_widgets := '["attention","orders","stock","inbox","kpis","pipeline"]'::jsonb;
    when 'services_bookings' then
      v_preset := 'services_bookings';
      v_widgets := '["attention","appointments","inbox","followups","kpis","pipeline"]'::jsonb;
    when 'restaurant_food' then
      v_preset := 'retail_orders';
      v_widgets := '["attention","orders","inbox","stock","kpis","appointments"]'::jsonb;
    when 'beauty_wellness' then
      v_preset := 'services_bookings';
      v_widgets := '["attention","appointments","inbox","followups","kpis"]'::jsonb;
    when 'consulting' then
      v_preset := 'sales_quotes';
      v_widgets := '["attention","requests","pipeline","appointments","followups","inbox"]'::jsonb;
    else
      raise exception 'Unsupported business template';
  end case;

  oid := public.create_workspace_server(
    p_user,
    p_name,
    p_slug,
    p_industry,
    p_currency,
    p_timezone
  );

  update public.organization_settings
  set business_template = p_business_template,
      dashboard_preset = v_preset,
      dashboard_config = jsonb_build_object('widgets',v_widgets),
      dashboard_config_version = 1,
      template_applied_at = now(),
      updated_at = now()
  where organization_id = oid;

  if not found then
    raise exception 'Workspace settings were not created';
  end if;

  return oid;
end
$$;

revoke all on function public.create_workspace_template_server(uuid,text,text,text,text,text,text)
  from public, anon, authenticated;
grant execute on function public.create_workspace_template_server(uuid,text,text,text,text,text,text)
  to service_role;
