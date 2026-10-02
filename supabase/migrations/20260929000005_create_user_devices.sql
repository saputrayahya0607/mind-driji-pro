-- ==============================================================================
-- MIND DRIJI - Database Migration: User Devices & Device Identity
-- File: supabase/migrations/20260929000005_create_user_devices.sql
-- Description: Membuat tabel public.user_devices untuk mendukung multi-device,
--              menambahkan kolom device_id ke tabel monitoring existing,
--              dan memperbarui constraint unik agar data antar-perangkat tidak bertabrakan.
-- ==============================================================================

-- 1. Tabel public.user_devices (Multi-device tanpa batas)
CREATE TABLE IF NOT EXISTS public.user_devices (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
  device_id text NOT NULL,
  device_name text,
  manufacturer text,
  model text,
  android_version text,
  app_version text,
  first_seen_at timestamptz NOT NULL DEFAULT now(),
  last_seen_at timestamptz NOT NULL DEFAULT now(),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  CONSTRAINT uq_user_device UNIQUE(user_id, device_id)
);

-- Index untuk efisiensi query device milik user dan urutan aktivitas terakhir
CREATE INDEX IF NOT EXISTS idx_user_devices_user ON public.user_devices (user_id);
CREATE INDEX IF NOT EXISTS idx_user_devices_user_last_seen ON public.user_devices (user_id, last_seen_at DESC);

-- Aktifkan Row Level Security (RLS)
ALTER TABLE public.user_devices ENABLE ROW LEVEL SECURITY;

-- RLS Policies untuk user_devices: Pemilik data hanya dapat mengakses data miliknya sendiri
DROP POLICY IF EXISTS "Users can view own devices" ON public.user_devices;
CREATE POLICY "Users can view own devices"
  ON public.user_devices
  FOR SELECT
  USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can insert own devices" ON public.user_devices;
CREATE POLICY "Users can insert own devices"
  ON public.user_devices
  FOR INSERT
  WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update own devices" ON public.user_devices;
CREATE POLICY "Users can update own devices"
  ON public.user_devices
  FOR UPDATE
  USING (auth.uid() = user_id)
  WITH CHECK (auth.uid() = user_id);

-- Trigger auto-update updated_at untuk user_devices
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM pg_proc WHERE proname = 'handle_updated_at'
  ) THEN
    DROP TRIGGER IF EXISTS on_user_devices_updated ON public.user_devices;
    CREATE TRIGGER on_user_devices_updated
      BEFORE UPDATE ON public.user_devices
      FOR EACH ROW
      EXECUTE FUNCTION public.handle_updated_at();
  END IF;
END $$;

-- 2. Tambahkan device_id ke tabel monitoring existing (Backward-compatible)
-- Catatan: Nilai default 'legacy' digunakan murni untuk data lama yang dibuat
-- sebelum arsitektur device identity diterapkan, agar data existing tetap utuh.

-- A. screen_time_daily
ALTER TABLE public.screen_time_daily
  ADD COLUMN IF NOT EXISTS device_id text NOT NULL DEFAULT 'legacy';

-- Ganti constraint lama (user_id, date) dengan (user_id, device_id, date)
ALTER TABLE public.screen_time_daily
  DROP CONSTRAINT IF EXISTS uq_screen_time_user_date;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_screen_time_user_device_date'
  ) THEN
    ALTER TABLE public.screen_time_daily
      ADD CONSTRAINT uq_screen_time_user_device_date UNIQUE (user_id, device_id, date);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_screen_time_user_device_date
  ON public.screen_time_daily (user_id, device_id, date);

-- B. app_usage_daily
ALTER TABLE public.app_usage_daily
  ADD COLUMN IF NOT EXISTS device_id text NOT NULL DEFAULT 'legacy';

-- Ganti constraint lama (user_id, date, package_name) dengan (user_id, device_id, date, package_name)
ALTER TABLE public.app_usage_daily
  DROP CONSTRAINT IF EXISTS uq_app_usage_user_date_package;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'uq_app_usage_user_device_date_package'
  ) THEN
    ALTER TABLE public.app_usage_daily
      ADD CONSTRAINT uq_app_usage_user_device_date_package UNIQUE (user_id, device_id, date, package_name);
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_app_usage_user_device_date
  ON public.app_usage_daily (user_id, device_id, date);

-- C. doomscroll_sessions
ALTER TABLE public.doomscroll_sessions
  ADD COLUMN IF NOT EXISTS device_id text NOT NULL DEFAULT 'legacy';

CREATE INDEX IF NOT EXISTS idx_doomscroll_user_device
  ON public.doomscroll_sessions (user_id, device_id, started_at DESC);

-- D. eye_monitoring_sessions
ALTER TABLE public.eye_monitoring_sessions
  ADD COLUMN IF NOT EXISTS device_id text NOT NULL DEFAULT 'legacy';

CREATE INDEX IF NOT EXISTS idx_eye_monitoring_user_device
  ON public.eye_monitoring_sessions (user_id, device_id, started_at DESC);

-- 3. GRANT Hak Akses ke authenticated role
GRANT SELECT, INSERT, UPDATE ON public.user_devices TO authenticated;
