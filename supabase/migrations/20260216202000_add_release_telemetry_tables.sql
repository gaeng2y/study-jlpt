-- Minimal release telemetry storage (analytics + crash/error logs).

create table if not exists public.analytics_events (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  event_name text not null,
  properties jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

create table if not exists public.client_error_logs (
  id bigint generated always as identity primary key,
  user_id uuid references auth.users(id) on delete set null,
  message text not null,
  stack text,
  context text,
  is_fatal boolean not null default false,
  created_at timestamptz not null default now()
);

create index if not exists idx_analytics_events_user_created
  on public.analytics_events(user_id, created_at desc);

create index if not exists idx_analytics_events_name_created
  on public.analytics_events(event_name, created_at desc);

create index if not exists idx_client_error_logs_user_created
  on public.client_error_logs(user_id, created_at desc);

create index if not exists idx_client_error_logs_fatal_created
  on public.client_error_logs(is_fatal, created_at desc);

alter table public.analytics_events enable row level security;
alter table public.client_error_logs enable row level security;

drop policy if exists "analytics_events_owner_insert" on public.analytics_events;
create policy "analytics_events_owner_insert"
on public.analytics_events
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "analytics_events_owner_select" on public.analytics_events;
create policy "analytics_events_owner_select"
on public.analytics_events
for select to authenticated
using (auth.uid() = user_id);

drop policy if exists "client_error_logs_owner_insert" on public.client_error_logs;
create policy "client_error_logs_owner_insert"
on public.client_error_logs
for insert to authenticated
with check (auth.uid() = user_id);

drop policy if exists "client_error_logs_owner_select" on public.client_error_logs;
create policy "client_error_logs_owner_select"
on public.client_error_logs
for select to authenticated
using (auth.uid() = user_id);
