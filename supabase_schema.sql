-- ============================================================================
-- BUGASAN POS & COMPUTER ACCOUNTING SYSTEM - SUPABASE DATABASE SCHEMA
-- Compatible with Supabase PostgreSQL (REST API & RLS)
-- Project: https://tagnuihzrbjxhqmzhduc.supabase.co
-- ============================================================================

-- 1. Enable UUID Extension
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 2. USERS TABLE
CREATE TABLE IF NOT EXISTS public.users (
    id BIGSERIAL PRIMARY KEY,
    user_id INT UNIQUE,
    email TEXT UNIQUE NOT NULL,
    password TEXT NOT NULL,
    role_id INT NOT NULL DEFAULT 3, -- 1: Admin, 2: Manager, 3: Cashier
    first_name TEXT NOT NULL,
    middle_name TEXT DEFAULT '',
    last_name TEXT NOT NULL,
    phone_number TEXT DEFAULT '',
    address TEXT DEFAULT '',
    status TEXT DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SUPPLIERS TABLE
CREATE TABLE IF NOT EXISTS public.suppliers (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    contact_person TEXT,
    phone TEXT,
    email TEXT,
    address TEXT,
    supplied_varieties TEXT,
    status TEXT DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. PRODUCTS (RICE INVENTORY) TABLE
CREATE TABLE IF NOT EXISTS public.products (
    id BIGSERIAL PRIMARY KEY,
    barcode TEXT UNIQUE NOT NULL,
    name TEXT NOT NULL,
    category TEXT DEFAULT 'Regular', -- Premium, Regular, Specialty, Glutinous
    unit TEXT DEFAULT '50kg sack',   -- 'kg', '25kg sack', '50kg sack'
    cost_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    selling_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    stock_quantity NUMERIC(12,2) NOT NULL DEFAULT 0,
    min_threshold NUMERIC(12,2) NOT NULL DEFAULT 10,
    supplier_id BIGINT REFERENCES public.suppliers(id) ON DELETE SET NULL,
    supplier_name TEXT DEFAULT '',
    harvest_batch TEXT DEFAULT '',
    expiry_date DATE,
    status TEXT DEFAULT 'In Stock',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. TRANSACTIONS / SALES TABLE
CREATE TABLE IF NOT EXISTS public.transactions (
    id BIGSERIAL PRIMARY KEY,
    invoice_no TEXT UNIQUE NOT NULL,
    cashier_id INT,
    cashier_name TEXT NOT NULL,
    items JSONB NOT NULL DEFAULT '[]'::jsonb,
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 12,
    tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_type TEXT DEFAULT 'None', -- 'None', 'Senior Citizen', 'PWD'
    discount_id TEXT DEFAULT '',
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_method TEXT NOT NULL DEFAULT 'Cash', -- 'Cash', 'GCash', 'Maya', 'MariBank'
    payment_reference TEXT DEFAULT '',
    amount_tendered NUMERIC(12,2) NOT NULL DEFAULT 0,
    change_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status TEXT DEFAULT 'Completed', -- 'Completed', 'Voided'
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 6. RESTOCK HISTORY TABLE
CREATE TABLE IF NOT EXISTS public.restock_history (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT REFERENCES public.products(id) ON DELETE CASCADE,
    product_name TEXT NOT NULL,
    barcode TEXT NOT NULL,
    quantity NUMERIC(12,2) NOT NULL,
    unit TEXT NOT NULL,
    supplier_id BIGINT,
    supplier_name TEXT,
    cost_per_unit NUMERIC(12,2),
    total_cost NUMERIC(12,2),
    restocked_by TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 7. EMPLOYEES & PAYROLL TABLE
CREATE TABLE IF NOT EXISTS public.employees (
    id BIGSERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    role TEXT NOT NULL,
    daily_rate NUMERIC(10,2) NOT NULL DEFAULT 0,
    days_worked NUMERIC(5,1) NOT NULL DEFAULT 0,
    overtime_hours NUMERIC(5,1) NOT NULL DEFAULT 0,
    sss_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    philhealth_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    pagibig_deduction NUMERIC(10,2) NOT NULL DEFAULT 0,
    other_deductions NUMERIC(10,2) NOT NULL DEFAULT 0,
    gross_pay NUMERIC(12,2) NOT NULL DEFAULT 0,
    net_pay NUMERIC(12,2) NOT NULL DEFAULT 0,
    period TEXT DEFAULT 'Current Cutoff',
    status TEXT DEFAULT 'Active',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 8. LOSSES & SPOILAGE TABLE
CREATE TABLE IF NOT EXISTS public.losses (
    id BIGSERIAL PRIMARY KEY,
    product_id BIGINT REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    quantity NUMERIC(12,2) NOT NULL,
    unit TEXT NOT NULL,
    reason TEXT NOT NULL, -- 'Damaged Sack', 'Pest/Weevil Infestation', 'Moisture Spoilage', 'Spillage'
    cost_loss NUMERIC(12,2) NOT NULL DEFAULT 0,
    logged_by TEXT,
    notes TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 9. SYSTEM AUDIT LOGS TABLE
CREATE TABLE IF NOT EXISTS public.system_logs (
    id BIGSERIAL PRIMARY KEY,
    user_name TEXT NOT NULL,
    user_role TEXT NOT NULL,
    action TEXT NOT NULL, -- 'LOGIN', 'SALE', 'VOID_TRANSACTION', 'RESTOCK', 'USER_UPDATE', etc.
    details TEXT NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. SYSTEM SETTINGS TABLE
CREATE TABLE IF NOT EXISTS public.settings (
    key TEXT PRIMARY KEY,
    value TEXT NOT NULL,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- ============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES FOR SUPABASE ANON KEY ACCESS
-- ============================================================================
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.suppliers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.products ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.restock_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.employees ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.losses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.system_logs ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.settings ENABLE ROW LEVEL SECURITY;

-- Allow full public / anon access for POS desktop/web operation
CREATE POLICY "Anon full access users" ON public.users FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access suppliers" ON public.suppliers FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access products" ON public.products FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access transactions" ON public.transactions FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access restock" ON public.restock_history FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access employees" ON public.employees FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access losses" ON public.losses FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access system_logs" ON public.system_logs FOR ALL TO anon USING (true) WITH CHECK (true);
CREATE POLICY "Anon full access settings" ON public.settings FOR ALL TO anon USING (true) WITH CHECK (true);

-- ============================================================================
-- SEED INITIAL DATA
-- ============================================================================

-- Initial Users (Admin, Manager, Cashier, Temp User)
INSERT INTO public.users (user_id, email, password, role_id, first_name, middle_name, last_name, phone_number, address, status)
VALUES 
    (1, 'admin@bugasan.ph', 'admin123', 1, 'MARIA', 'SANTOS', 'DELA CRUZ', '+639171234567', 'Manila, Philippines', 'Active'),
    (2, 'manager@bugasan.ph', 'manager123', 2, 'EDUARDO', 'REYES', 'CRUZ', '+639182345678', 'Quezon City, Philippines', 'Active'),
    (3, 'cashier@bugasan.ph', 'cashier123', 3, 'ANA', 'GARCIA', 'REYES', '+639193456789', 'Pasig City, Philippines', 'Active'),
    (4, 'newuser@bugasan.ph', 'temp4321', 3, 'JUAN', 'PEDRO', 'DE LA CRUZ', '+639204567890', 'Makati City, Philippines', 'Active')
ON CONFLICT (email) DO NOTHING;

-- Initial Suppliers
INSERT INTO public.suppliers (id, name, contact_person, phone, email, address, supplied_varieties, status)
VALUES 
    (1, 'Central Luzon Rice Millers Corp.', 'Engr. Roberto Mendoza', '+639175550192', 'clrm_rice@millers.ph', 'Maharlika Highway, Cabanatuan City, Nueva Ecija', 'Sinandomeng, Well-Milled', 'Active'),
    (2, 'Isabela Golden Grains Trading', 'Carmen Gutierrez', '+639185550481', 'sales@isabelagrains.ph', 'San Fermin, Cauayan City, Isabela', 'Dinorado, Jasmine Fragrant', 'Active'),
    (3, 'Mindoro Agri-Producers Cooperative', 'Danilo Villanueva', '+639195550734', 'danilo@mindoroagricoop.org', 'Barangay Lumangbayan, Calapan, Oriental Mindoro', 'Brown Rice, Malagkit (Glutinous)', 'Active'),
    (4, 'Bulacan Milling & Grain Depot', 'Manuel Santos', '+639205550912', 'msantos@bulacanmill.ph', 'Poblacion, Bocaue, Bulacan', 'Sinandomeng, Regular Milled', 'Inactive')
ON CONFLICT (id) DO NOTHING;

-- Initial Rice Products
INSERT INTO public.products (barcode, name, category, unit, cost_price, selling_price, stock_quantity, min_threshold, supplier_id, supplier_name, harvest_batch, expiry_date, status)
VALUES 
    ('48000101', 'Sinandomeng Special (50kg sack)', 'Regular', '50kg sack', 2100.00, 2350.00, 42.00, 10.00, 1, 'Central Luzon Rice Millers Corp.', 'BATCH-2026-NE-01', '2027-04-15', 'In Stock'),
    ('48000102', 'Sinandomeng Special (Per Kilo)', 'Regular', 'kg', 42.00, 48.00, 185.00, 30.00, 1, 'Central Luzon Rice Millers Corp.', 'BATCH-2026-NE-01', '2027-04-15', 'In Stock'),
    ('48000103', 'Dinorado Premium Fragrant (50kg sack)', 'Premium', '50kg sack', 2300.00, 2600.00, 25.00, 8.00, 2, 'Isabela Golden Grains Trading', 'BATCH-2026-ISA-04', '2027-05-20', 'In Stock'),
    ('48000104', 'Dinorado Premium Fragrant (Per Kilo)', 'Premium', 'kg', 46.00, 53.00, 110.00, 25.00, 2, 'Isabela Golden Grains Trading', 'BATCH-2026-ISA-04', '2027-05-20', 'In Stock'),
    ('48000105', 'Jasmine Super White (50kg sack)', 'Premium', '50kg sack', 2400.00, 2700.00, 30.00, 10.00, 2, 'Isabela Golden Grains Trading', 'BATCH-2026-ISA-08', '2027-06-10', 'In Stock'),
    ('48000106', 'Jasmine Super White (Per Kilo)', 'Premium', 'kg', 48.00, 55.00, 95.00, 20.00, 2, 'Isabela Golden Grains Trading', 'BATCH-2026-ISA-08', '2027-06-10', 'In Stock'),
    ('48000107', 'Well-Milled Rice Grade 1 (50kg sack)', 'Regular', '50kg sack', 1850.00, 2100.00, 55.00, 15.00, 1, 'Central Luzon Rice Millers Corp.', 'BATCH-2026-NE-09', '2027-03-30', 'In Stock'),
    ('48000108', 'Well-Milled Rice Grade 1 (Per Kilo)', 'Regular', 'kg', 37.00, 43.00, 230.00, 40.00, 1, 'Central Luzon Rice Millers Corp.', 'BATCH-2026-NE-09', '2027-03-30', 'In Stock'),
    ('48000109', 'Glutinous Rice (Malagkit) (25kg sack)', 'Glutinous', '25kg sack', 1550.00, 1750.00, 4.00, 8.00, 3, 'Mindoro Agri-Producers Cooperative', 'BATCH-2026-MIN-02', '2027-02-28', 'Low Stock'),
    ('48000110', 'Glutinous Rice (Malagkit) (Per Kilo)', 'Glutinous', 'kg', 62.00, 72.00, 38.00, 15.00, 3, 'Mindoro Agri-Producers Cooperative', 'BATCH-2026-MIN-02', '2027-02-28', 'In Stock'),
    ('48000111', 'Organic Black Rice (10kg bag)', 'Specialty', '10kg sack', 750.00, 880.00, 2.00, 5.00, 3, 'Mindoro Agri-Producers Cooperative', 'BATCH-2025-MIN-11', '2026-11-25', 'Critical Low Stock'),
    ('48000112', 'Premium Brown Rice (25kg sack)', 'Specialty', '25kg sack', 1280.00, 1450.00, 12.00, 5.00, 3, 'Mindoro Agri-Producers Cooperative', 'BATCH-2026-MIN-05', '2027-07-15', 'In Stock')
ON CONFLICT (barcode) DO NOTHING;

-- Initial Employees (HR/Payroll)
INSERT INTO public.employees (name, role, daily_rate, days_worked, overtime_hours, sss_deduction, philhealth_deduction, pagibig_deduction, other_deductions, gross_pay, net_pay, period, status)
VALUES 
    ('Maria Santos', 'Store Administrator', 800.00, 13.0, 4.0, 550.00, 250.00, 100.00, 0.00, 10900.00, 10000.00, 'Nov 1 - Nov 15, 2026', 'Active'),
    ('Eduardo Cruz', 'Branch Manager', 700.00, 13.0, 6.0, 500.00, 225.00, 100.00, 0.00, 9725.00, 8900.00, 'Nov 1 - Nov 15, 2026', 'Active'),
    ('Ana Reyes', 'Senior Cashier', 550.00, 12.0, 3.0, 400.00, 180.00, 100.00, 150.00, 6856.25, 6026.25, 'Nov 1 - Nov 15, 2026', 'Active'),
    ('Jeffrey Tan', 'POS Cashier', 520.00, 12.0, 0.0, 380.00, 170.00, 100.00, 0.00, 6240.00, 5590.00, 'Nov 1 - Nov 15, 2026', 'Active'),
    ('Danilo Ramos', 'Warehouse & Bag Handler', 500.00, 13.0, 8.0, 360.00, 160.00, 100.00, 0.00, 7125.00, 6505.00, 'Nov 1 - Nov 15, 2026', 'Active')
ON CONFLICT DO NOTHING;

-- Initial Settings
INSERT INTO public.settings (key, value)
VALUES 
    ('store_name', 'Bugasan Rice Retail & Trading'),
    ('store_address', 'Stall 14-16, Poblacion Central Public Market, Philippines'),
    ('store_tin', '452-981-002-000-VAT'),
    ('store_phone', '+63 917 882 1904'),
    ('tax_rate', '12'),
    ('currency', '₱'),
    ('low_stock_threshold', '10')
ON CONFLICT (key) DO NOTHING;

-- Initial Audit Log
INSERT INTO public.system_logs (user_name, user_role, action, details)
VALUES 
    ('System Administrator', 'Admin', 'SYSTEM_INITIALIZED', 'Database schema and seed records initialized successfully.')
ON CONFLICT DO NOTHING;
-- ============================================================================
-- BUGASAN POS - ADD SALES & SALES ITEMS TABLES
-- Execute in Supabase SQL Editor:
-- https://supabase.com/dashboard/project/tagnuihzrbjxhqmzhduc/sql/new
-- ============================================================================

-- 1. SALES TABLE
CREATE TABLE IF NOT EXISTS public.sales (
    id BIGSERIAL PRIMARY KEY,
    transaction_id BIGINT REFERENCES public.transactions(id) ON DELETE CASCADE,
    invoice_no TEXT NOT NULL,
    cashier_id INT,
    cashier_name TEXT NOT NULL,
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    tax_rate NUMERIC(5,2) NOT NULL DEFAULT 12,
    tax_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    discount_type TEXT DEFAULT 'None',
    discount_id TEXT DEFAULT '',
    discount_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    total_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    payment_method TEXT NOT NULL DEFAULT 'Cash',
    payment_reference TEXT DEFAULT '',
    amount_tendered NUMERIC(12,2) NOT NULL DEFAULT 0,
    change_amount NUMERIC(12,2) NOT NULL DEFAULT 0,
    status TEXT DEFAULT 'Completed',
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. SALES_ITEMS (ITEMIZED BREAKDOWN PER SALE)
CREATE TABLE IF NOT EXISTS public.sales_items (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT REFERENCES public.sales(id) ON DELETE CASCADE,
    transaction_id BIGINT REFERENCES public.transactions(id) ON DELETE CASCADE,
    invoice_no TEXT NOT NULL,
    product_id BIGINT REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    barcode TEXT NOT NULL,
    unit TEXT DEFAULT '50kg sack',
    unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    quantity NUMERIC(12,2) NOT NULL DEFAULT 1,
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. SALES_ITEM (COMPATIBILITY ALIAS TABLE)
CREATE TABLE IF NOT EXISTS public.sales_item (
    id BIGSERIAL PRIMARY KEY,
    sale_id BIGINT,
    transaction_id BIGINT REFERENCES public.transactions(id) ON DELETE CASCADE,
    invoice_no TEXT NOT NULL,
    product_id BIGINT REFERENCES public.products(id) ON DELETE SET NULL,
    product_name TEXT NOT NULL,
    barcode TEXT NOT NULL,
    unit TEXT DEFAULT '50kg sack',
    unit_price NUMERIC(12,2) NOT NULL DEFAULT 0,
    quantity NUMERIC(12,2) NOT NULL DEFAULT 1,
    subtotal NUMERIC(12,2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ENABLE ROW LEVEL SECURITY
ALTER TABLE public.sales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_item ENABLE ROW LEVEL SECURITY;

-- 5. RLS POLICIES (FULL READ & WRITE ACCESS FOR ANON CLIENTS)
DROP POLICY IF EXISTS "Anon Sales Access" ON public.sales;
CREATE POLICY "Anon Sales Access" ON public.sales FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Anon Sales Items Access" ON public.sales_items;
CREATE POLICY "Anon Sales Items Access" ON public.sales_items FOR ALL USING (true) WITH CHECK (true);

DROP POLICY IF EXISTS "Anon Sales Item Access" ON public.sales_item;
CREATE POLICY "Anon Sales Item Access" ON public.sales_item FOR ALL USING (true) WITH CHECK (true);

-- 6. GRANT API PERMISSIONS
GRANT ALL ON TABLE public.sales TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.sales_items TO anon, authenticated, service_role;
GRANT ALL ON TABLE public.sales_item TO anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO anon, authenticated, service_role;

-- 7. INITIAL SEED RECORDS
INSERT INTO public.sales (transaction_id, invoice_no, cashier_id, cashier_name, subtotal, tax_rate, tax_amount, discount_type, discount_amount, total_amount, payment_method, amount_tendered, change_amount, status)
VALUES 
    (1, 'INV-20261112-0001', 3, 'ANA REYES', 2350.00, 12.00, 282.00, 'None', 0.00, 2632.00, 'Cash', 3000.00, 368.00, 'Completed')
ON CONFLICT DO NOTHING;

INSERT INTO public.sales_items (sale_id, transaction_id, invoice_no, product_id, product_name, barcode, unit, unit_price, quantity, subtotal)
VALUES 
    (1, 1, 'INV-20261112-0001', 1, 'Sinandomeng Special (50kg sack)', '480001000001', '50kg sack', 2350.00, 1.00, 2350.00)
ON CONFLICT DO NOTHING;

INSERT INTO public.sales_item (sale_id, transaction_id, invoice_no, product_id, product_name, barcode, unit, unit_price, quantity, subtotal)
VALUES 
    (1, 1, 'INV-20261112-0001', 1, 'Sinandomeng Special (50kg sack)', '480001000001', '50kg sack', 2350.00, 1.00, 2350.00)
ON CONFLICT DO NOTHING;
