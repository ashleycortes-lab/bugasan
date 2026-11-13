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
