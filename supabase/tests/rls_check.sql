-- RLS verification script for 일어톡톡
-- Run in Supabase SQL editor after migrations are applied.
-- This script simulates authenticated sessions by setting JWT claims.

begin;

-- 0) Safety check: RLS enabled
select schemaname, tablename, rowsecurity
from pg_tables
where schemaname = 'public'
  and tablename in (
    'profiles',
    'content_items',
    'user_srs',
    'daily_stats',
    'user_favorites',
    'quest_defs',
    'user_quest_progress'
)
order by tablename;

-- 1) Prepare two fake users
-- Use fixed UUIDs to make test deterministic.
-- NOTE: This only inserts auth.users rows for test. Remove after test if needed.
insert into auth.users (
  id,
  aud,
  role,
  email,
  encrypted_password,
  email_confirmed_at,
  created_at,
  updated_at,
  raw_app_meta_data,
  raw_user_meta_data,
  is_anonymous
)
values
  (
    '11111111-1111-1111-1111-111111111111',
    'authenticated',
    'authenticated',
    'rls-user-a@example.com',
    crypt('test-password', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"anonymous","providers":["anonymous"]}'::jsonb,
    '{"name":"RLS User A"}'::jsonb,
    true
  ),
  (
    '22222222-2222-2222-2222-222222222222',
    'authenticated',
    'authenticated',
    'rls-user-b@example.com',
    crypt('test-password', gen_salt('bf')),
    now(),
    now(),
    now(),
    '{"provider":"anonymous","providers":["anonymous"]}'::jsonb,
    '{"name":"RLS User B"}'::jsonb,
    true
  )
on conflict (id) do nothing;

-- Trigger should auto-create profiles, but ensure they exist.
insert into public.profiles (id, display_name)
values
  ('11111111-1111-1111-1111-111111111111', 'RLS User A'),
  ('22222222-2222-2222-2222-222222222222', 'RLS User B')
on conflict (id) do nothing;

-- Create per-user rows to test isolation.
insert into public.daily_stats (user_id, day, cards_done, is_completed)
values
  ('11111111-1111-1111-1111-111111111111', current_date, 3, true),
  ('22222222-2222-2222-2222-222222222222', current_date, 7, true)
on conflict (user_id, day) do update set cards_done = excluded.cards_done;

-- 2) Simulate user A context
set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"role":"authenticated","sub":"11111111-1111-1111-1111-111111111111"}',
  true
);

-- A should see only A profile
select 'A sees profiles' as test_name, id, display_name
from public.profiles
order by id;

-- A should see only A daily_stats
select 'A sees daily_stats' as test_name, user_id, day, cards_done
from public.daily_stats
order by user_id;

-- A should NOT be able to insert/update B rows
-- Expect: permission denied / violates RLS policy
-- Uncomment one by one to verify failure behavior.
-- insert into public.daily_stats (user_id, day, cards_done) values ('22222222-2222-2222-2222-222222222222', current_date, 99);
-- update public.profiles set display_name = 'hacked' where id = '22222222-2222-2222-2222-222222222222';

-- 3) Simulate user B context
select set_config(
  'request.jwt.claims',
  '{"role":"authenticated","sub":"22222222-2222-2222-2222-222222222222"}',
  true
);

select 'B sees profiles' as test_name, id, display_name
from public.profiles
order by id;

select 'B sees daily_stats' as test_name, user_id, day, cards_done
from public.daily_stats
order by user_id;

-- 4) Public content should be visible to authenticated users
select 'content visible' as test_name, id, kind, jlpt_level, jp
from public.content_items
where is_active = true
limit 5;

-- 5) Reset role and finish
reset role;

-- Keep test data for manual inspection by default.
-- If you want cleanup, run:
-- delete from public.daily_stats where user_id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
-- delete from public.profiles where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');
-- delete from auth.users where id in ('11111111-1111-1111-1111-111111111111', '22222222-2222-2222-2222-222222222222');

commit;
