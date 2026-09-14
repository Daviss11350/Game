-- ============================================
-- LISTRAYL CHESS - COMPLETE SUPABASE SETUP
-- ============================================

-- 1. PLAYERS TABLE
CREATE TABLE IF NOT EXISTS public.players (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    wins INTEGER NOT NULL DEFAULT 0,
    losses INTEGER NOT NULL DEFAULT 0,
    games INTEGER NOT NULL DEFAULT 0,
    coins INTEGER NOT NULL DEFAULT 0,
    xp INTEGER NOT NULL DEFAULT 0,
    rank TEXT NOT NULL DEFAULT 'Rookie',
    streak INTEGER NOT NULL DEFAULT 0,
    best_streak INTEGER NOT NULL DEFAULT 0,
    active_mythic TEXT NOT NULL DEFAULT 'storm',
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. Make sure required player columns exist
ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS name TEXT;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS wins INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS losses INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS games INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS coins INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS xp INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS rank TEXT NOT NULL DEFAULT 'Rookie';

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS streak INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS best_streak INTEGER NOT NULL DEFAULT 0;

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS active_mythic TEXT NOT NULL DEFAULT 'storm';

ALTER TABLE public.players
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();


-- ============================================
-- 3. ROOMS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS public.rooms (
    room_code TEXT PRIMARY KEY,
    host_uid UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    white_uid UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    white_name TEXT NOT NULL,
    black_uid UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    black_name TEXT,
    white_rank TEXT NOT NULL DEFAULT 'Rookie',
    black_rank TEXT,
    board JSONB NOT NULL,
    turn TEXT NOT NULL DEFAULT 'w',
    status TEXT NOT NULL DEFAULT 'waiting',
    winner UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    rewarded_by JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Add columns if rooms already existed
ALTER TABLE public.rooms
ADD COLUMN IF NOT EXISTS black_name TEXT;

ALTER TABLE public.rooms
ADD COLUMN IF NOT EXISTS white_rank TEXT NOT NULL DEFAULT 'Rookie';

ALTER TABLE public.rooms
ADD COLUMN IF NOT EXISTS black_rank TEXT;

ALTER TABLE public.rooms
ADD COLUMN IF NOT EXISTS rewarded_by JSONB NOT NULL DEFAULT '{}'::jsonb;

ALTER TABLE public.rooms
ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();


-- ============================================
-- 4. INDEXES
-- ============================================

CREATE INDEX IF NOT EXISTS players_xp_idx
ON public.players (xp DESC);

CREATE INDEX IF NOT EXISTS players_wins_idx
ON public.players (wins DESC);

CREATE INDEX IF NOT EXISTS rooms_status_idx
ON public.rooms (status);

CREATE INDEX IF NOT EXISTS rooms_created_idx
ON public.rooms (created_at DESC);


-- ============================================
-- 5. ROW LEVEL SECURITY
-- ============================================

ALTER TABLE public.players ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.rooms ENABLE ROW LEVEL SECURITY;


-- Remove old policies if present
DROP POLICY IF EXISTS players_authenticated_all
ON public.players;

DROP POLICY IF EXISTS players_select_authenticated
ON public.players;

DROP POLICY IF EXISTS players_insert_authenticated
ON public.players;

DROP POLICY IF EXISTS players_update_authenticated
ON public.players;

DROP POLICY IF EXISTS rooms_authenticated_all
ON public.rooms;

DROP POLICY IF EXISTS rooms_select_authenticated
ON public.rooms;

DROP POLICY IF EXISTS rooms_insert_authenticated
ON public.rooms;

DROP POLICY IF EXISTS rooms_update_authenticated
ON public.rooms;


-- PLAYERS: authenticated users can read/write
CREATE POLICY players_select_authenticated
ON public.players
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY players_insert_authenticated
ON public.players
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY players_update_authenticated
ON public.players
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);


-- ROOMS: everyone authenticated can create/read/update rooms
CREATE POLICY rooms_select_authenticated
ON public.rooms
FOR SELECT
TO authenticated
USING (true);

CREATE POLICY rooms_insert_authenticated
ON public.rooms
FOR INSERT
TO authenticated
WITH CHECK (true);

CREATE POLICY rooms_update_authenticated
ON public.rooms
FOR UPDATE
TO authenticated
USING (true)
WITH CHECK (true);


-- ============================================
-- 6. ENABLE REALTIME SAFELY
-- ============================================

DO $$
BEGIN

    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'players'
    ) THEN
        ALTER PUBLICATION supabase_realtime
        ADD TABLE public.players;
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
        AND schemaname = 'public'
        AND tablename = 'rooms'
    ) THEN
        ALTER PUBLICATION supabase_realtime
        ADD TABLE public.rooms;
    END IF;

END $$;


-- ============================================
-- 7. VERIFY EVERYTHING
-- ============================================

SELECT
    table_schema,
    table_name
FROM information_schema.tables
WHERE table_schema = 'public'
AND table_name IN ('players', 'rooms')
ORDER BY table_name;
