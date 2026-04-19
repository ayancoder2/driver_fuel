-- 10_reset_test_users.sql
-- Confirm ALL users so everyone can log in immediately
UPDATE auth.users 
SET email_confirmed_at = NOW(), 
    last_sign_in_at = NOW() 
WHERE email_confirmed_at IS NULL;

-- Final sync of drivers table
INSERT INTO public.drivers (id, full_name, email, phone)
SELECT 
    id, 
    COALESCE(raw_user_meta_data->>'full_name', 'Verified Driver'), 
    email, 
    COALESCE(raw_user_meta_data->>'phone', '')
FROM auth.users
WHERE id NOT IN (SELECT id FROM public.drivers)
ON CONFLICT (id) DO NOTHING;
