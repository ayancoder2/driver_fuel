-- 02_add_missing_columns.sql
-- Adds missing timestamp and pricing columns to the orders table.
-- Run this in: Supabase Dashboard -> SQL Editor

-- Add accepted_at column (set when driver accepts the order)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS accepted_at TIMESTAMPTZ;

-- Add arrived_at column (set when driver marks as arrived at delivery location)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS arrived_at TIMESTAMPTZ;

-- Add completed_at column (set when order is finalized)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ;

-- Add price_per_gallon column (used for earnings calculation)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS price_per_gallon NUMERIC(10, 4);

-- Add unit_price as an alias column (fallback used in DeliveryProofScreen)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS unit_price NUMERIC(10, 4);

-- Add is_emergency flag if missing
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS is_emergency BOOLEAN DEFAULT FALSE;

-- Add fuel_quantity if missing (ensures migration from older schema versions)
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS fuel_quantity NUMERIC;

-- Also ensure fuel_quantity_gallons is present for backward compatibility if needed
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS fuel_quantity_gallons NUMERIC;

-- Add total_amount if missing
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS total_amount NUMERIC(10, 2) DEFAULT 0;

-- Additional missing columns check
ALTER TABLE public.orders
  ADD COLUMN IF NOT EXISTS meter_reading_start NUMERIC,
  ADD COLUMN IF NOT EXISTS meter_reading_end NUMERIC,
  ADD COLUMN IF NOT EXISTS pickup_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS delivery_photo_url TEXT,
  ADD COLUMN IF NOT EXISTS completed_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS assigned_at TIMESTAMPTZ,
  ADD COLUMN IF NOT EXISTS driver_earning NUMERIC(10, 2) DEFAULT 0;

-- Refresh the schema cache so PostgREST picks up the new columns immediately
NOTIFY pgrst, 'reload schema';
