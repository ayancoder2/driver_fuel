-- 07_signup_trigger.sql
-- 1. Create a function to automatically create a driver profile
CREATE OR REPLACE FUNCTION public.handle_new_driver()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.drivers (id, full_name, email, phone)
  VALUES (
    new.id,
    new.raw_user_meta_data->>'full_name',
    new.email,
    new.raw_user_meta_data->>'phone'
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_driver();
