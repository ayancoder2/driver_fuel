-- 05_hard_reset_drivers.sql
-- 1. Drop the table and its dependencies
DROP TABLE IF EXISTS public.drivers CASCADE;

-- 2. Recreate the table with the correct schema from scratch
CREATE TABLE public.drivers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    status TEXT DEFAULT 'offline',
    avatar_url TEXT,
    vehicle_type TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Re-enable RLS
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;

-- 4. Re-apply policies
CREATE POLICY "Public profile view" ON public.drivers FOR SELECT USING (true);
CREATE POLICY "Drivers can manage their own profile" ON public.drivers FOR ALL USING (auth.uid() = id);

-- 5. Force schema reload
NOTIFY pgrst, 'reload schema';
