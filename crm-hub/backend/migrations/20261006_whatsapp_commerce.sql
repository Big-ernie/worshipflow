-- Big Ernie CRM Hub: WhatsApp commerce and structured request intake
-- Production project: anedlarzwpestjratbsj
-- Idempotent where practical. Existing CRM tables and revenue flows are preserved.

begin;

alter table public.products_services
  add column if not exists item_type text not null default 'service',
  add column if not exists is_orderable boolean not null default false,
  add column if not exists inventory_tracking boolean not null default false,
  add column if not exists stock_quantity numeric,
  add column if not exists low_stock_threshold numeric,
  add column if not exists image_url text,
  add column if not exists whatsapp_catalog_enabled boolean not null default false,
  add column if not exists sort_order integer not null default 0;

do $$ begin
  if not exists (select 1 from pg_constraint where conname='products_services_item_type_check') then
    alter table public.products_services
      add constraint products_services_item_type_check
      check (item_type in ('product','service','hybrid'));
  end if;
end $$;

alter table public.conversations
  add column if not exists last_inbound_at timestamptz,
  add column if not exists last_outbound_at timestamptz;

create table if not exists public.customer_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  conversation_id uuid references public.conversations(id) on delete set null,
  request_number text not null,
  request_type text not null default 'enquiry',
  source text not null default 'whatsapp',
  status text not null default 'new',
  title text,
  notes text,
  total numeric not null default 0,
  currency text not null default 'GHS',
  linked_deal_id uuid references public.deals(id) on delete set null,
  linked_quote_id uuid references public.quotes(id) on delete set null,
  linked_appointment_id uuid references public.appointments(id) on delete set null,
  owner_user_id uuid references public.profiles(id) on delete set null,
  next_action text,
  next_followup_at timestamptz,
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, request_number)
);

do $$ begin
  if not exists (select 1 from pg_constraint where conname='customer_requests_type_check') then
    alter table public.customer_requests add constraint customer_requests_type_check
      check (request_type in ('enquiry','quote','order','booking','support'));
  end if;
  if not exists (select 1 from pg_constraint where conname='customer_requests_status_check') then
    alter table public.customer_requests add constraint customer_requests_status_check
      check (status in ('new','collecting','ready','in_progress','waiting_customer','won','completed','cancelled','lost'));
  end if;
end $$;

create table if not exists public.request_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  request_id uuid not null references public.customer_requests(id) on delete cascade,
  product_service_id uuid references public.products_services(id) on delete set null,
  item_name text not null,
  quantity numeric not null default 1,
  unit_price numeric,
  currency text not null default 'GHS',
  notes text,
  options jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.intake_sessions (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  conversation_id uuid not null references public.conversations(id) on delete cascade,
  contact_id uuid references public.contacts(id) on delete set null,
  request_type text not null,
  state text not null default 'start',
  product_service_id uuid references public.products_services(id) on delete set null,
  request_id uuid references public.customer_requests(id) on delete set null,
  context jsonb not null default '{}'::jsonb,
  expires_at timestamptz not null default (now() + interval '2 hours'),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

do $$ begin
  if not exists (select 1 from pg_constraint where conname='intake_sessions_type_check') then
    alter table public.intake_sessions add constraint intake_sessions_type_check
      check (request_type in ('quote','order','enquiry','support'));
  end if;
end $$;

create index if not exists customer_requests_org_status_idx on public.customer_requests(organization_id,status,created_at desc);
create index if not exists customer_requests_conversation_idx on public.customer_requests(organization_id,conversation_id,created_at desc);
create index if not exists customer_requests_contact_idx on public.customer_requests(contact_id);
create index if not exists customer_requests_conversation_fk_idx on public.customer_requests(conversation_id);
create index if not exists customer_requests_linked_deal_idx on public.customer_requests(linked_deal_id);
create index if not exists customer_requests_linked_quote_idx on public.customer_requests(linked_quote_id);
create index if not exists customer_requests_linked_appointment_idx on public.customer_requests(linked_appointment_id);
create index if not exists customer_requests_owner_idx on public.customer_requests(owner_user_id);
create index if not exists request_items_request_idx on public.request_items(request_id);
create index if not exists request_items_org_idx on public.request_items(organization_id);
create index if not exists request_items_product_idx on public.request_items(product_service_id);
create index if not exists intake_sessions_active_idx on public.intake_sessions(organization_id,conversation_id,expires_at desc);
create index if not exists intake_sessions_contact_idx on public.intake_sessions(contact_id);
create index if not exists intake_sessions_conversation_idx on public.intake_sessions(conversation_id);
create index if not exists intake_sessions_product_idx on public.intake_sessions(product_service_id);
create index if not exists intake_sessions_request_idx on public.intake_sessions(request_id);
create index if not exists messages_conversation_time_idx on public.messages(organization_id,conversation_id,occurred_at);

drop index if exists public.conversations_recent_idx;

alter table public.customer_requests enable row level security;
alter table public.request_items enable row level security;
alter table public.intake_sessions enable row level security;

drop policy if exists customer_requests_r on public.customer_requests;
drop policy if exists customer_requests_i on public.customer_requests;
drop policy if exists customer_requests_u on public.customer_requests;
drop policy if exists customer_requests_d on public.customer_requests;
create policy customer_requests_r on public.customer_requests for select to authenticated
  using (private.has_module_access(organization_id,'whatsapp','view'));
create policy customer_requests_i on public.customer_requests for insert to authenticated
  with check (private.has_module_access(organization_id,'whatsapp','edit'));
create policy customer_requests_u on public.customer_requests for update to authenticated
  using (private.has_module_access(organization_id,'whatsapp','edit'))
  with check (private.has_module_access(organization_id,'whatsapp','edit'));
create policy customer_requests_d on public.customer_requests for delete to authenticated
  using (private.has_module_access(organization_id,'whatsapp','edit'));

drop policy if exists request_items_r on public.request_items;
drop policy if exists request_items_i on public.request_items;
drop policy if exists request_items_u on public.request_items;
drop policy if exists request_items_d on public.request_items;
create policy request_items_r on public.request_items for select to authenticated
  using (private.has_module_access(organization_id,'whatsapp','view'));
create policy request_items_i on public.request_items for insert to authenticated
  with check (private.has_module_access(organization_id,'whatsapp','edit'));
create policy request_items_u on public.request_items for update to authenticated
  using (private.has_module_access(organization_id,'whatsapp','edit'))
  with check (private.has_module_access(organization_id,'whatsapp','edit'));
create policy request_items_d on public.request_items for delete to authenticated
  using (private.has_module_access(organization_id,'whatsapp','edit'));

drop policy if exists intake_sessions_r on public.intake_sessions;
drop policy if exists intake_sessions_i on public.intake_sessions;
drop policy if exists intake_sessions_u on public.intake_sessions;
drop policy if exists intake_sessions_d on public.intake_sessions;
create policy intake_sessions_r on public.intake_sessions for select to authenticated
  using (private.has_module_access(organization_id,'whatsapp','view'));
create policy intake_sessions_i on public.intake_sessions for insert to authenticated
  with check (private.has_module_access(organization_id,'whatsapp','edit'));
create policy intake_sessions_u on public.intake_sessions for update to authenticated
  using (private.has_module_access(organization_id,'whatsapp','edit'))
  with check (private.has_module_access(organization_id,'whatsapp','edit'));
create policy intake_sessions_d on public.intake_sessions for delete to authenticated
  using (private.has_module_access(organization_id,'whatsapp','edit'));

grant select,insert,update,delete on public.customer_requests to authenticated;
grant select,insert,update,delete on public.request_items to authenticated;
grant select,insert,update,delete on public.intake_sessions to authenticated;

commit;
