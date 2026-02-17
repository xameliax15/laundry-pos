// Supabase Edge Function: payment-webhook
// Webhook handler untuk menerima notifikasi pembayaran dari Midtrans
//
// POST /functions/v1/payment-webhook
// Body: Midtrans notification payload
// Response: { status: 'ok' }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"
import { crypto } from "https://deno.land/std@0.168.0/crypto/mod.ts"

const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface MidtransNotification {
    transaction_time: string
    transaction_status: string
    transaction_id: string
    status_message: string
    status_code: string
    signature_key: string
    settlement_time?: string
    payment_type: string
    order_id: string
    merchant_id: string
    gross_amount: string
    fraud_status: string
    currency: string
    acquirer?: string
    issuer?: string
    shopeepay_reference_number?: string
}

// Generate SHA512 signature for verification
async function generateSignature(
    orderId: string,
    statusCode: string,
    grossAmount: string,
    serverKey: string
): Promise<string> {
    const signatureKey = `${orderId}${statusCode}${grossAmount}${serverKey}`
    const encoder = new TextEncoder()
    const data = encoder.encode(signatureKey)
    const hashBuffer = await crypto.subtle.digest('SHA-512', data)
    const hashArray = Array.from(new Uint8Array(hashBuffer))
    const hashHex = hashArray.map(b => b.toString(16).padStart(2, '0')).join('')
    return hashHex
}

serve(async (req: Request) => {
    // Handle CORS preflight request
    if (req.method === 'OPTIONS') {
        return new Response('ok', { headers: corsHeaders })
    }

    try {
        const notification = await req.json() as MidtransNotification

        console.log('Received webhook notification:', JSON.stringify(notification, null, 2))

        // Get server key and Supabase credentials from environment
        const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY')
        const supabaseUrl = Deno.env.get('SUPABASE_URL')
        const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')

        if (!serverKey || !supabaseUrl || !supabaseServiceKey) {
            console.error('Missing environment variables')
            return new Response(
                JSON.stringify({ error: 'Server configuration error' }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Verify signature from Midtrans
        const expectedSignature = await generateSignature(
            notification.order_id,
            notification.status_code,
            notification.gross_amount,
            serverKey
        )

        if (notification.signature_key !== expectedSignature) {
            console.error('Invalid signature')
            console.error('Expected:', expectedSignature)
            console.error('Received:', notification.signature_key)
            return new Response(
                JSON.stringify({ error: 'Invalid signature' }),
                { status: 401, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        // Initialize Supabase client with service role key
        const supabase = createClient(supabaseUrl, supabaseServiceKey)

        // Determine payment status based on transaction_status
        let paymentStatus: string
        switch (notification.transaction_status) {
            case 'capture':
            case 'settlement':
                paymentStatus = 'lunas'
                break
            case 'pending':
                paymentStatus = 'pending'
                break
            case 'deny':
            case 'cancel':
            case 'failure':
                paymentStatus = 'gagal'
                break
            case 'expire':
                paymentStatus = 'expired'
                break
            default:
                paymentStatus = 'pending'
        }

        console.log(`Updating payment status to: ${paymentStatus} for transaction: ${notification.transaction_id}`)

        // Update pembayaran table based on qris_id (transaction_id from Midtrans)
        const { data, error } = await supabase
            .from('pembayaran')
            .update({
                status: paymentStatus,
                gateway_response: notification,
                tanggal_bayar: notification.settlement_time || notification.transaction_time,
            })
            .eq('qris_id', notification.transaction_id)
            .select()

        if (error) {
            console.error('Database update error:', error)
            return new Response(
                JSON.stringify({ error: 'Failed to update payment status', details: error.message }),
                { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
            )
        }

        console.log('Payment updated:', data)

        // If payment is successful (lunas), also update the related transaksi
        if (paymentStatus === 'lunas' && data && data.length > 0) {
            const pembayaran = data[0]

            // Check if all payments for this transaction are complete
            const { data: transaksiData } = await supabase
                .from('transaksi')
                .select('total_harga')
                .eq('id', pembayaran.transaksi_id)
                .single()

            if (transaksiData) {
                const { data: allPayments } = await supabase
                    .from('pembayaran')
                    .select('jumlah, status')
                    .eq('transaksi_id', pembayaran.transaksi_id)
                    .eq('status', 'lunas')

                const totalPaid = (allPayments || []).reduce((sum, p) => sum + p.jumlah, 0)

                if (totalPaid >= transaksiData.total_harga) {
                    console.log('Transaction fully paid, can update transaksi status if needed')
                    // Optional: Update transaksi status or trigger other business logic
                }
            }
        }

        return new Response(
            JSON.stringify({ status: 'ok', payment_status: paymentStatus }),
            { status: 200, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )

    } catch (error) {
        console.error('Webhook error:', error)
        return new Response(
            JSON.stringify({ error: 'Internal server error', details: error.message }),
            { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
        )
    }
})
