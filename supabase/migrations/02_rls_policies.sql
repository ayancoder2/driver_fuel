-- 02_rls_policies.sql
-- Row Level Security (RLS) policies for FuelDirect

-- Enable RLS on all tables
ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.drivers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.driver_vehicles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.orders ENABLE ROW LEVEL SECURITY;

-- 1. Profiles (Customers) Policies
-- Allow drivers to read customer profiles who have an order
CREATE POLICY "Drivers can view customer profiles" ON public.profiles
    FOR SELECT USING (auth.role() = 'authenticated');

CREATE POLICY "Users can manage their own profile" ON public.profiles
    FOR ALL USING (auth.uid() = id);

-- 2. Drivers Policies
CREATE POLICY "Public profile view" ON public.drivers
    FOR SELECT USING (true); -- Public or Authenticated

CREATE POLICY "Drivers can manage their own profile" ON public.drivers
    FOR ALL USING (auth.uid() = id);

-- 3. Driver Vehicles Policies
CREATE POLICY "Drivers can manage their own vehicles" ON public.driver_vehicles
    FOR ALL USING (auth.uid() = driver_id);

CREATE POLICY "Everyone can view vehicle info" ON public.driver_vehicles
    FOR SELECT USING (true);

-- 4. Orders Policies
CREATE POLICY "Drivers can view available or assigned orders" ON public.orders
    FOR SELECT USING (
        auth.uid() = driver_id OR status = 'pending'
    );

CREATE POLICY "Drivers can update assigned orders" ON public.orders
    FOR UPDATE USING (auth.uid() = driver_id)
    WITH CHECK (auth.uid() = driver_id);

-- Storage Policies (Buckets must exist: 'driver_documents', 'avatars')
-- These are usually set in the Storage tab, but documented here:
-- bucket 'avatars': public read, owner write
-- bucket 'driver_documents': owner read/write
