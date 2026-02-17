-- Migration: Add QRIS Payment Gateway Support
-- Run this migration in Supabase SQL Editor

-- 1. Add new columns to pembayaran table for QRIS payment support
ALTER TABLE pembayaran ADD COLUMN IF NOT EXISTS qris_id TEXT;
ALTER TABLE pembayaran ADD COLUMN IF NOT EXISTS qris_string TEXT;
ALTER TABLE pembayaran ADD COLUMN IF NOT EXISTS qris_url TEXT;
ALTER TABLE pembayaran ADD COLUMN IF NOT EXISTS qris_expired_at TIMESTAMPTZ;
ALTER TABLE pembayaran ADD COLUMN IF NOT EXISTS payment_gateway TEXT;
ALTER TABLE pembayaran ADD COLUMN IF NOT EXISTS gateway_response JSONB;

-- 2. Create index for faster QRIS lookups
CREATE INDEX IF NOT EXISTS idx_pembayaran_qris_id ON pembayaran(qris_id) WHERE qris_id IS NOT NULL;

-- 3. Add 'expired' to possible status values (if using enum, otherwise skip)
-- ALTER TYPE payment_status ADD VALUE IF NOT EXISTS 'expired';
-- ALTER TYPE payment_status ADD VALUE IF NOT EXISTS 'cancelled';
-- ALTER TYPE payment_status ADD VALUE IF NOT EXISTS 'gagal';

-- 4. Create payment gateway configuration table
CREATE TABLE IF NOT EXISTS payment_gateway_config (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    gateway_name TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT false,
    server_key TEXT, -- Note: In production, use Supabase Vault for sensitive keys
    client_key TEXT,
    is_production BOOLEAN DEFAULT false,
    webhook_url TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. Insert default Midtrans configuration (update keys manually in dashboard)
INSERT INTO payment_gateway_config (gateway_name, is_active, is_production)
VALUES ('midtrans', true, false)
ON CONFLICT (gateway_name) DO NOTHING;

-- 6. Enable Row Level Security (RLS) for payment_gateway_config
ALTER TABLE payment_gateway_config ENABLE ROW LEVEL SECURITY;

-- 7. Create policy: Only authenticated users with admin role can read/write config
CREATE POLICY "Admin can manage payment config" ON payment_gateway_config
    FOR ALL
    USING (auth.jwt() ->> 'role' = 'owner')
    WITH CHECK (auth.jwt() ->> 'role' = 'owner');

-- 8. Create policy: Edge Functions can read config using service role key
-- (Service role bypasses RLS, so no explicit policy needed)

-- 9. Add updated_at trigger for payment_gateway_config
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_payment_gateway_config_modtime
    BEFORE UPDATE ON payment_gateway_config
    FOR EACH ROW
    EXECUTE FUNCTION update_modified_column();

-- 10. Grant permissions for Edge Functions
GRANT SELECT ON payment_gateway_config TO anon;
GRANT SELECT ON payment_gateway_config TO authenticated;
GRANT ALL ON payment_gateway_config TO service_role;

-- 11. Add comment for documentation
COMMENT ON TABLE payment_gateway_config IS 'Configuration for payment gateways like Midtrans, Xendit. Server keys should be stored securely or in Vault.';
COMMENT ON COLUMN pembayaran.qris_id IS 'Transaction ID from payment gateway for QRIS payments';
COMMENT ON COLUMN pembayaran.qris_string IS 'QR code string data that can be rendered as QR image';
COMMENT ON COLUMN pembayaran.qris_url IS 'URL to QR code image from payment gateway';
COMMENT ON COLUMN pembayaran.qris_expired_at IS 'Expiration timestamp for QRIS payment';
COMMENT ON COLUMN pembayaran.payment_gateway IS 'Payment gateway used: midtrans, xendit, etc';
COMMENT ON COLUMN pembayaran.gateway_response IS 'Full response/webhook payload from payment gateway';
