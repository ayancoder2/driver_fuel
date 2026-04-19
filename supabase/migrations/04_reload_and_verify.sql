-- 04_reload_and_verify.sql
-- 1. Force Supabase PostgREST to reload the schema cache
NOTIFY pgrst, 'reload schema';

-- 2. Ensure all columns exist (Final safety check)
DO $$ 
BEGIN
    -- Check for email column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='email') THEN
        ALTER TABLE public.drivers ADD COLUMN email TEXT;
    END IF;
    
    -- Check for status column
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='drivers' AND column_name='status') THEN
        ALTER TABLE public.drivers ADD COLUMN status TEXT DEFAULT 'offline';
    END IF;
END $$;

-- 3. Clear any potential constraint naming conflicts
ALTER TABLE public.drivers DROP CONSTRAINT IF EXISTS drivers_email_key;
ALTER TABLE public.drivers ADD CONSTRAINT drivers_email_key UNIQUE (email);
