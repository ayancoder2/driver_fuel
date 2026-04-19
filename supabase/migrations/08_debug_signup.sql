-- 08_debug_signup.sql
-- 1. Check if the latest users have metadata
SELECT id, email, created_at, raw_user_meta_data 
FROM auth.users 
ORDER BY created_at DESC 
LIMIT 5;

-- 2. Check if the trigger is active
SELECT trigger_name, event_manipulation, event_object_table, action_statement 
FROM information_schema.triggers 
WHERE event_object_table = 'users' AND trigger_name = 'on_auth_user_created';

-- 3. Check for any recent errors in the drivers table
-- (PostgreSQL doesn't show triggers errors here, but we can check if anything exists)
SELECT count(*) FROM public.drivers;
