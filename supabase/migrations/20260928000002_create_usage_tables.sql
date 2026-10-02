-- ==============================================================================
-- MIND DRIJI - Database Migration: Screen Time & App Usage Daily Tables
-- File: supabase/migrations/20260928000002_create_usage_tables.sql
-- Description: Membuat tabel public.screen_time_daily, public.app_usage_daily,
--              RLS policies, trigger updated_at, dan GRANT privilege
-- ==============================================================================

-- 1. Tabel public.screen_time_daily
CREATE TABLE IF NOT EXISTS public.screen_time_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date date NOT NULL,
  total_usage_millis bigint NOT NULL DEFAULT 0,
  collected_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_screen_time_user_date UNIQUE (user_id, date)
);

-- Index untuk performa query berdasarkan user dan tanggal
CREATE INDEX IF NOT EXISTS idx_screen_time_user_date ON public.screen_time_daily (user_id, date);

-- 2. Tabel public.app_usage_daily
CREATE TABLE IF NOT EXISTS public.app_usage_daily (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  date date NOT NULL,
  package_name text NOT NULL,
  app_name text NOT NULL,
  usage_millis bigint NOT NULL DEFAULT 0,
  collected_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_app_usage_user_date_package UNIQUE (user_id, date, package_name)
);

-- Index untuk performa query aplikasi per user dan tanggal
CREATE INDEX IF NOT EXISTS idx_app_usage_user_date ON public.app_usage_daily (user_id, date);
CREATE INDEX IF NOT EXISTS idx_app_usage_package ON public.app_usage_daily (package_name);

-- 3. Aktifkan Row Level Security (RLS)
ALTER TABLE public.screen_time_daily ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.app_usage_daily ENABLE ROW LEVEL SECURITY;

-- 4. RLS Policies untuk screen_time_daily
DROP POLICY IF EXISTS "Users can view own screen time" ON public.screen_time_daily;
CREATE POLICY "Users can view own screen time"
  ON public.screen_time_daily
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own screen time" ON public.screen_time_daily;
CREATE POLICY "Users can insert own screen time"
  ON public.screen_time_daily
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own screen time" ON public.screen_time_daily;
CREATE POLICY "Users can update own screen time"
  ON public.screen_time_daily
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own screen time" ON public.screen_time_daily;
CREATE POLICY "Users can delete own screen time"
  ON public.screen_time_daily
  FOR DELETE
  USING (auth.uid() = user_id);

-- 5. RLS Policies untuk app_usage_daily
DROP POLICY IF EXISTS "Users can view own app usage" ON public.app_usage_daily;
CREATE POLICY "Users can view own app usage"
  ON public.app_usage_daily
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own app usage" ON public.app_usage_daily;
CREATE POLICY "Users can insert own app usage"
  ON public.app_usage_daily
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own app usage" ON public.app_usage_daily;
CREATE POLICY "Users can update own app usage"
  ON public.app_usage_daily
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete own app usage" ON public.app_usage_daily;
CREATE POLICY "Users can delete own app usage"
  ON public.app_usage_daily
  FOR DELETE
  USING (auth.uid() = user_id);

-- 6. Trigger Otomatis updated_at
DROP TRIGGER IF EXISTS set_screen_time_updated_at ON public.screen_time_daily;
CREATE TRIGGER set_screen_time_updated_at
  BEFORE UPDATE ON public.screen_time_daily
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

DROP TRIGGER IF EXISTS set_app_usage_updated_at ON public.app_usage_daily;
CREATE TRIGGER set_app_usage_updated_at
  BEFORE UPDATE ON public.app_usage_daily
  FOR EACH ROW
  EXECUTE FUNCTION public.handle_updated_at();

-- 7. Grant Privileges kepada role authenticated
GRANT ALL ON TABLE public.screen_time_daily TO authenticated;
GRANT ALL ON TABLE public.app_usage_daily TO authenticated;
