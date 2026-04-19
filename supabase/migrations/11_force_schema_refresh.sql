-- 11_force_schema_refresh.sql
-- This command forces Supabase to refresh its API cache for ALL tables
NOTIFY pgrst, 'reload schema';

-- Also, let's double check that the 'year' column definitely exists 
-- and is an INTEGER (this won't hurt if it's already correct)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='driver_vehicles' AND column_name='year') THEN
        ALTER TABLE public.driver_vehicles ADD COLUMN year INTEGER;
    END IF;
END $$;
