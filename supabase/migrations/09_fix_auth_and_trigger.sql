-- 09_fix_auth_and_trigger.sql

-- 1. Auto-confirm all existing users so they can log in immediately
UPDATE auth.users SET email_confirmed_at = NOW() WHERE email_confirmed_at IS NULL;

-- 2. Create driver profiles for any users who signed up but missed the trigger
INSERT INTO public.drivers (id, full_name, email, phone)
SELECT 
    id, 
    raw_user_meta_data->>'full_name', 
    email, 
    raw_user_meta_data->>'phone'
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.drivers)
ON CONFLICT (id) DO NOTHING;

-- 3. Ensure the Trigger function is using correct syntax for your Supabase version
CREATE OR REPLACE FUNCTION public.handle_new_driver()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.drivers (id, full_name, email, phone)
  VALUES (
    new.id,
    COALESCE(new.raw_user_meta_data->>'full_name', 'New Driver'),
    new.email,
    COALESCE(new.raw_user_meta_data->>'phone', '')
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
