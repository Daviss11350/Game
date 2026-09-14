-- LISTRAYL CHESS complete Supabase setup
-- Run this entire file in Supabase SQL Editor.

create extension if not exists pgcrypto;

create table if not exists public.players (
  id uuid primary key,
  name text not null,
  wins integer not null default 0,
  losses integer not null default 0,
  games integer not null default 0,
  coins integer not null default 0,
  xp integer not null default 0,
  rank text not null default 'Rookie',
  streak integer not null default 0,
  best_streak integer not null default 0,
  active_mythic text not null default 'storm',
  updated_at timestamptz not null default now()
);

create table if not exists public.rooms (
  room_code text primary key,
  host_uid uuid not null,
  white_uid uuid not null,
  white_name text not null,
  black_uid uuid,
  black_name text,
  white_rank text not null default 'Rookie',
  black_rank text,
  board jsonb not null,
  turn text not null default 'w',
  status text not null default 'waiting',
  winner uuid,
  rewarded_by jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.players enable row level security;
alter table public.rooms enable row level security;

drop policy if exists players_public_all on public.players;
create policy players_public_all on public.players for all to anon, authenticated using (true) with check (true);

drop policy if exists rooms_public_all on public.rooms;
create policy rooms_public_all on public.rooms for all to anon, authenticated using (true) with check (true);

-- Keep existing databases compatible with this version.
alter table public.rooms add column if not exists black_name text;
alter table public.rooms add column if not exists white_rank text not null default 'Rookie';
alter table public.rooms add column if not exists black_rank text;
alter table public.rooms add column if not exists black_uid uuid;
alter table public.rooms add column if not exists white_name text;
alter table public.rooms add column if not exists board jsonb;
alter table public.rooms add column if not exists turn text not null default 'w';
alter table public.rooms add column if not exists status text not null default 'waiting';
alter table public.rooms add column if not exists winner uuid;
alter table public.rooms add column if not exists rewarded_by jsonb not null default '{}'::jsonb;
alter table public.rooms add column if not exists created_at timestamptz not null default now();

-- Idempotent Realtime setup: only add a table if it is not already present.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='rooms'
  ) then
    alter publication supabase_realtime add table public.rooms;
  end if;
  if not exists (
    select 1 from pg_publication_tables
    where pubname='supabase_realtime' and schemaname='public' and tablename='players'
  ) then
    alter publication supabase_realtime add table public.players;
  end if;
end $$;

-- Useful indexes.
create index if not exists rooms_status_idx on public.rooms(status);
create index if not exists players_xp_idx on public.players(xp desc);
