-- 03_fix_drivers_table.sql
-- Safely add missing columns to the drivers table if they don't exist

ALTER TABLE IF EXISTS public.drivers 
ADD COLUMN IF NOT EXISTS email TEXT,
ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'offline',
ADD COLUMN IF NOT EXISTS avatar_url TEXT,
ADD COLUMN IF NOT EXISTS vehicle_type TEXT;

-- Ensure email is unique if it was just added
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint WHERE conname = 'drivers_email_key'
    ) THEN
        ALTER TABLE public.drivers ADD CONSTRAINT drivers_email_key UNIQUE (email);
    END IF;
END $$;
