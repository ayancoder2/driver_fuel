-- Migration: Add fcm_token to drivers table
-- Run this in Supabase Dashboard → SQL Editor
-- Project: fsxiioldnxdzidcunmma (FuelDirect)

-- 1. Add fcm_token to drivers table (stores driver's FCM push token)
ALTER TABLE drivers 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 2. Ensure profiles.fcm_token exists (for customer notifications)
ALTER TABLE profiles 
ADD COLUMN IF NOT EXISTS fcm_token TEXT;

-- 3. Add index for faster token lookups (optional but recommended)
CREATE INDEX IF NOT EXISTS idx_drivers_fcm_token ON drivers(fcm_token) WHERE fcm_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;

-- Verify
SELECT 'drivers.fcm_token' AS column_check, column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'drivers' AND column_name = 'fcm_token'
UNION ALL
SELECT 'profiles.fcm_token', column_name, data_type 
FROM information_schema.columns 
WHERE table_name = 'profiles' AND column_name = 'fcm_token';
