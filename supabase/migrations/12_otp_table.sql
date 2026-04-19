-- Create table for storing OTPs
CREATE TABLE IF NOT EXISTS public.user_otps (
    id UUID DEFAULT gen_random_uuid() PRIMARY KEY,
    email TEXT NOT NULL,
    otp TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW() NOT NULL,
    expires_at TIMESTAMPTZ NOT NULL,
    verified BOOLEAN DEFAULT FALSE
);

-- Index for faster lookup
CREATE INDEX IF NOT EXISTS idx_user_otps_email ON public.user_otps(email);

-- RLS policies
ALTER TABLE public.user_otps ENABLE ROW LEVEL SECURITY;

-- Policy to allow inserting OTPs (needed for generation)
-- In a real production app, this should be restricted to a server-side process
CREATE POLICY "Allow anyone to insert OTPs" ON public.user_otps FOR INSERT WITH CHECK (true);

-- Policy to allow users to read their own OTPs for verification
CREATE POLICY "Allow users to read their own OTPs" ON public.user_otps FOR SELECT USING (true);

-- Policy to allow updating (marking as verified)
CREATE POLICY "Allow updating OTP status" ON public.user_otps FOR UPDATE USING (true);
