-- ==============================================================================
-- MIND DRIJI - Database Migration: Eye Monitoring Sessions Table
-- File: supabase/migrations/20260928000004_create_eye_monitoring_sessions.sql
-- Description: Membuat tabel public.eye_monitoring_sessions,
--              RLS policies, trigger updated_at, dan GRANT privilege
-- ==============================================================================

-- 1. Tabel public.eye_monitoring_sessions
CREATE TABLE IF NOT EXISTS public.eye_monitoring_sessions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  started_at timestamptz NOT NULL,
  ended_at timestamptz,
  duration_millis bigint NOT NULL DEFAULT 0,
  average_ear double precision NOT NULL DEFAULT 0.0,
  min_ear double precision NOT NULL DEFAULT 0.0,
  eye_closure_events integer NOT NULL DEFAULT 0,
  blink_count integer NOT NULL DEFAULT 0,
  collected_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Index untuk query sesi monitoring mata berdasarkan user dan waktu mulai
CREATE INDEX IF NOT EXISTS idx_eye_monitoring_sessions_user ON public.eye_monitoring_sessions (user_id, started_at DESC);

-- 2. Aktifkan Row Level Security (RLS)
ALTER TABLE public.eye_monitoring_sessions ENABLE ROW LEVEL SECURITY;

-- 3. RLS Policies untuk eye_monitoring_sessions
DROP POLICY IF EXISTS "Users can view own eye monitoring sessions" ON public.eye_monitoring_sessions;
CREATE POLICY "Users can view own eye monitoring sessions"
  ON public.eye_monitoring_sessions
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own eye monitoring sessions" ON public.eye_monitoring_sessions;
CREATE POLICY "Users can insert own eye monitoring sessions"
  ON public.eye_monitoring_sessions
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own eye monitoring sessions" ON public.eye_monitoring_sessions;
CREATE POLICY "Users can update own eye monitoring sessions"
  ON public.eye_monitoring_sessions
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- 4. Trigger auto-update updated_at jika fungsi handle_updated_at sudah ada
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'handle_updated_at'
  ) THEN
    DROP TRIGGER IF EXISTS on_eye_monitoring_sessions_updated ON public.eye_monitoring_sessions;
    CREATE TRIGGER on_eye_monitoring_sessions_updated
      BEFORE UPDATE ON public.eye_monitoring_sessions
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;
END $$;

-- 5. Grant hak akses ke role authenticated
GRANT SELECT, INSERT, UPDATE ON TABLE public.eye_monitoring_sessions TO authenticated;
