
-- Big Ernie CRM Hub: publicity and press distribution tracking.
-- Manual, owner-approved campaign management only. No third-party submissions.
create table if not exists public.pr_campaigns (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  title text not null check (char_length(btrim(title)) between 1 and 180),
  destination_url text not null check (destination_url ~* '^https?://'),
  provider text not null default 'Organic outreach',
  goal text,
  status text not null default 'draft' check (status in ('draft','approved','submitted','published','completed','cancelled')),
  budget_usd numeric(12,2) not null default 0 check (budget_usd >= 0),
  spend_usd numeric(12,2) not null default 0 check (spend_usd >= 0),
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (id, organization_id)
);
create table if not exists public.pr_placements (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  campaign_id uuid not null,
  publisher text not null check (char_length(btrim(publisher)) between 1 and 160),
  article_url text not null check (article_url ~* '^https?://'),
  placement_type text not null default 'syndicated' check (placement_type in ('earned','syndicated','sponsored')),
  verification_status text not null default 'unverified' check (verification_status in ('unverified','verified','removed')),
  published_on date,
  created_by uuid default auth.uid(),
  created_at timestamptz not null default now(),
  foreign key (campaign_id, organization_id) references public.pr_campaigns (id, organization_id) on delete cascade,
  unique (campaign_id, article_url)
);
create index if not exists pr_campaigns_workspace_idx on public.pr_campaigns (organization_id, created_at desc);
create index if not exists pr_placements_workspace_idx on public.pr_placements (organization_id, campaign_id);
alter table public.pr_campaigns enable row level security;
alter table public.pr_placements enable row level security;
revoke all on public.pr_campaigns from anon;
revoke all on public.pr_placements from anon;
grant select,insert,update,delete on public.pr_campaigns to authenticated;
grant select,insert,update,delete on public.pr_placements to authenticated;
create policy "pr_campaigns_read" on public.pr_campaigns for select to authenticated
 using (private.has_module_access(organization_id, 'reports', 'view'));
create policy "pr_campaigns_insert" on public.pr_campaigns for insert to authenticated
 with check (private.has_module_access(organization_id, 'reports', 'edit') and created_by = (select auth.uid()));
create policy "pr_campaigns_update" on public.pr_campaigns for update to authenticated
 using (private.has_module_access(organization_id, 'reports', 'edit'))
 with check (private.has_module_access(organization_id, 'reports', 'edit'));
create policy "pr_campaigns_delete" on public.pr_campaigns for delete to authenticated
 using (private.has_module_access(organization_id, 'reports', 'admin'));
create policy "pr_placements_read" on public.pr_placements for select to authenticated
 using (private.has_module_access(organization_id, 'reports', 'view'));
create policy "pr_placements_insert" on public.pr_placements for insert to authenticated
 with check (private.has_module_access(organization_id, 'reports', 'edit') and created_by = (select auth.uid()));
create policy "pr_placements_update" on public.pr_placements for update to authenticated
 using (private.has_module_access(organization_id, 'reports', 'edit'))
 with check (private.has_module_access(organization_id, 'reports', 'edit'));
create policy "pr_placements_delete" on public.pr_placements for delete to authenticated
 using (private.has_module_access(organization_id, 'reports', 'admin'));
