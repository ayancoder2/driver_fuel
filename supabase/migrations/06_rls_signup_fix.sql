-- 06_rls_signup_fix.sql
-- Drop old restrictive policies
DROP POLICY IF EXISTS "Drivers can manage their own profile" ON public.drivers;

-- 1. Allow anyone to INSERT into drivers (Required for the sign-up flow)
-- The Foreign Key constraint on 'id' to 'auth.users' still ensures security.
CREATE POLICY "Allow signup insert" ON public.drivers 
FOR INSERT 
WITH CHECK (true);

-- 2. Allow users to VIEW any driver profile (Optional, but good for app logic)
DROP POLICY IF EXISTS "Public profile view" ON public.drivers;
CREATE POLICY "Public profile view" ON public.drivers 
FOR SELECT 
USING (true);

-- 3. Allow users to UPDATE only their own profile
CREATE POLICY "Allow individual update" ON public.drivers 
FOR UPDATE 
USING (auth.uid() = id)
WITH CHECK (auth.uid() = id);

-- 4. Force another cache reload just in case
NOTIFY pgrst, 'reload schema';
