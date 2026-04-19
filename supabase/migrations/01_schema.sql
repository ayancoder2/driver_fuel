-- 01_schema.sql
-- Base schema for FuelDirect Driver App

-- 0. Handle Order Status Enum
DO $$ 
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'order_status') THEN
        CREATE TYPE order_status AS ENUM ('pending', 'assigned', 'accepted', 'driver_arrived', 'in_progress', 'delivered', 'completed', 'cancelled', 'scheduled');
    ELSE
        -- Add missing values if the type already exists
        BEGIN
            ALTER TYPE order_status ADD VALUE 'pending';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'assigned';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'delivered';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'accepted';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'driver_arrived';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'in_progress';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'completed';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'cancelled';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
        BEGIN
            ALTER TYPE order_status ADD VALUE 'scheduled';
        EXCEPTION WHEN duplicate_object THEN null;
        END;
    END IF;
END $$;

-- 1. Profiles (Customers)
CREATE TABLE IF NOT EXISTS public.profiles (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    phone_number TEXT,
    avatar_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Drivers
CREATE TABLE IF NOT EXISTS public.drivers (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    full_name TEXT,
    email TEXT UNIQUE,
    phone TEXT,
    status TEXT DEFAULT 'offline', -- 'online', 'offline'
    avatar_url TEXT,
    vehicle_type TEXT, -- e.g., 'Fuel Tanker - 01'
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. Driver Vehicles
CREATE TABLE IF NOT EXISTS public.driver_vehicles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    driver_id UUID REFERENCES public.drivers(id) ON DELETE CASCADE,
    make TEXT,
    model TEXT,
    year INTEGER,
    license_plate TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. Orders
CREATE TABLE IF NOT EXISTS public.orders (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES public.profiles(id), -- customer
    driver_id UUID REFERENCES public.drivers(id),
    status order_status DEFAULT 'pending', 
    delivery_address TEXT,
    fuel_type TEXT,
    fuel_quantity NUMERIC,
    delivery_lat DOUBLE PRECISION,
    delivery_lng DOUBLE PRECISION,
    customer_name TEXT,
    customer_phone TEXT,
    customer_avatar TEXT,
    total_amount NUMERIC(10, 2),
    meter_reading_start NUMERIC,
    meter_reading_end NUMERIC,
    pickup_photo_url TEXT,
    delivery_photo_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Indices for performance
CREATE INDEX IF NOT EXISTS idx_orders_driver_id ON public.orders(driver_id);
CREATE INDEX IF NOT EXISTS idx_orders_status ON public.orders(status);
CREATE INDEX IF NOT EXISTS idx_driver_vehicles_driver_id ON public.driver_vehicles(driver_id);
