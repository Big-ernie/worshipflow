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
