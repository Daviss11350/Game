# LISTRAYL CHESS — SUPABASE LIVE MULTIPLAYER

This build keeps the 15-file LISTRAYL CHESS structure and replaces Firebase with Supabase.

## 1. Create Supabase project
Open https://supabase.com/dashboard and create a project named `listrayl-chess`.

## 2. Enable Anonymous Auth
Supabase Dashboard → Authentication → Providers → Anonymous Sign-Ins → Enable.

## 3. Create the database tables
Open Supabase Dashboard → SQL Editor → New query and run:

```sql
create table if not exists public.players (
  id uuid primary key references auth.users(id) on delete cascade,
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
  host_uid uuid not null references auth.users(id) on delete cascade,
  white_uid uuid not null references auth.users(id) on delete cascade,
  white_name text not null,
  black_uid uuid references auth.users(id) on delete set null,
  black_name text,
  board jsonb not null,
  turn text not null default 'w',
  status text not null default 'waiting',
  winner uuid references auth.users(id) on delete set null,
  rewarded_by jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now()
);

alter table public.players enable row level security;
alter table public.rooms enable row level security;

drop policy if exists players_authenticated_all on public.players;
create policy players_authenticated_all on public.players
for all to authenticated using (true) with check (true);

drop policy if exists rooms_authenticated_all on public.rooms;
create policy rooms_authenticated_all on public.rooms
for all to authenticated using (true) with check (true);

-- Enable live database events for leaderboard and rooms.
alter publication supabase_realtime add table public.players;
alter publication supabase_realtime add table public.rooms;
```

If the final two `alter publication` commands say the table is already in the publication, that is okay.

## 4. Add your Supabase keys
Open `app.js` and find:

```js
const SUPABASE_CONFIG={url:'PASTE_SUPABASE_URL',anonKey:'PASTE_SUPABASE_ANON_KEY'};
```

Get them from Supabase:
Project Settings → API.

Use:
- Project URL → `url`
- Publishable/anon public key → `anonKey`

Do **not** put a `service_role` secret key in this website.

Example:

```js
const SUPABASE_CONFIG={
  url:'https://YOURPROJECT.supabase.co',
  anonKey:'YOUR_PUBLIC_ANON_OR_PUBLISHABLE_KEY'
};
```

## 5. Upload to GitHub
Upload all 15 files without renaming them.

## 6. Deploy to Vercel
Import the GitHub repository into Vercel and deploy.

## Included features
- Solo chess
- Live 1v1 rooms
- 6-character room codes
- Real player names
- Real-time board synchronization
- Live leaderboard
- Player statistics
- Mythic effects
- Shop
- XP and coins
- Match history
- Levels
- Achievements
- Missions
- Puzzles
- Animated victory result
- Mobile-first UI

## Important
The chess engine is lightweight and intended for the game MVP. It does not fully implement tournament-grade chess rules such as castling, en-passant and promotion/check validation.

The current RLS policies are intentionally simple for the MVP. Before a large public launch, move sensitive rewards/stats to trusted server-side logic so players cannot modify their own scores through the browser.

## Supabase setup
1. Open Supabase SQL Editor.
2. Run the complete `supabase.sql` file included in this project.
3. In Supabase Project Settings → API, copy the Project URL and anon/public key into `app.js`:
   `SUPABASE_CONFIG={url:'YOUR_PROJECT_URL',anonKey:'YOUR_ANON_KEY'}`
4. If Anonymous Sign-Ins are enabled, the app uses them. If they are not enabled, this build can fall back to a local UUID when the SQL policies allow public room access.
5. Realtime must be enabled for the `rooms` table; the included SQL adds it to `supabase_realtime`.
