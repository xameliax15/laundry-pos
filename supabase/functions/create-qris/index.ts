// Supabase Edge Function: create-qris
// Endpoint untuk membuat QRIS payment via Midtrans API
//
// POST /functions/v1/create-qris
// Body: { transaksi_id, amount, customer_name, customer_phone?, customer_email? }
// Response: { qris_id, qris_string, qris_url, expired_at, order_id, amount }

import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const corsHeaders = {
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
}

interface CreateQrisRequest {
  transaksi_id: string
  amount: number
  customer_name: string
  customer_phone?: string
  customer_email?: string
}

interface MidtransQrisResponse {
  status_code: string
  status_message: string
  transaction_id: string
  order_id: string
  merchant_id: string
  gross_amount: string
  currency: string
  payment_type: string
  transaction_time: string
  transaction_status: string
  fraud_status: string
  acquirer: string
  qr_string?: string
  actions?: Array<{
    name: string
    method: string
    url: string
  }>
}

serve(async (req: Request) => {
  // Handle CORS preflight request
  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { transaksi_id, amount, customer_name, customer_phone, customer_email } = 
      await req.json() as CreateQrisRequest

    // Validate input
    if (!transaksi_id || !amount || !customer_name) {
      return new Response(
        JSON.stringify({ error: 'Missing required fields: transaksi_id, amount, customer_name' }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Get Midtrans server key from environment
    const serverKey = Deno.env.get('MIDTRANS_SERVER_KEY')
    const isProduction = Deno.env.get('MIDTRANS_IS_PRODUCTION') === 'true'
    
    if (!serverKey) {
      return new Response(
        JSON.stringify({ error: 'Payment gateway not configured' }),
        { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Midtrans API URL
    const midtransBaseUrl = isProduction 
      ? 'https://api.midtrans.com' 
      : 'https://api.sandbox.midtrans.com'

    // Generate unique order ID
    const orderId = `LAUNDRY-${transaksi_id}-${Date.now()}`

    // Create QRIS charge request to Midtrans
    const chargePayload = {
      payment_type: 'qris',
      transaction_details: {
        order_id: orderId,
        gross_amount: Math.round(amount), // Midtrans requires integer
      },
      qris: {
        acquirer: 'gopay', // Default acquirer, bisa juga: airpay shopee, dana, etc
      },
      customer_details: {
        first_name: customer_name,
        phone: customer_phone || '',
        email: customer_email || 'customer@laundry.local',
      },
      item_details: [
        {
          id: transaksi_id,
          price: Math.round(amount),
          quantity: 1,
          name: 'Pembayaran Laundry',
        }
      ],
      custom_expiry: {
        expiry_duration: 15, // 15 minutes
        unit: 'minute'
      }
    }

    // Base64 encode server key for Basic Auth
    const authHeader = btoa(`${serverKey}:`)

    const midtransResponse = await fetch(`${midtransBaseUrl}/v2/charge`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Authorization': `Basic ${authHeader}`,
      },
      body: JSON.stringify(chargePayload),
    })

    const midtransData = await midtransResponse.json() as MidtransQrisResponse

    if (midtransData.status_code !== '201') {
      console.error('Midtrans error:', midtransData)
      return new Response(
        JSON.stringify({ 
          error: 'Failed to create QRIS', 
          details: midtransData.status_message 
        }),
        { status: 400, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
      )
    }

    // Extract QR code URL from actions
    let qrisUrl = ''
    if (midtransData.actions) {
      const qrAction = midtransData.actions.find(a => a.name === 'generate-qr-code')
      if (qrAction) {
        qrisUrl = qrAction.url
      }
    }

    // Calculate expiry time (15 minutes from now)
    const expiredAt = new Date(Date.now() + 15 * 60 * 1000).toISOString()

    // Return response
    const response = {
      qris_id: midtransData.transaction_id,
      qris_string: midtransData.qr_string || '',
      qris_url: qrisUrl,
      expired_at: expiredAt,
      order_id: midtransData.order_id,
      amount: parseFloat(midtransData.gross_amount),
      transaction_status: midtransData.transaction_status,
    }

    return new Response(
      JSON.stringify(response),
      { 
        status: 200, 
        headers: { ...corsHeaders, 'Content-Type': 'application/json' } 
      }
    )

  } catch (error) {
    console.error('Error:', error)
    return new Response(
      JSON.stringify({ error: 'Internal server error', details: error.message }),
      { status: 500, headers: { ...corsHeaders, 'Content-Type': 'application/json' } }
    )
  }
})
