const express = require('express');
const axios = require('axios');
const db = require('../db');
require('dotenv').config();

const router = express.Router();

async function getToken() {
  const key = process.env.MPESA_CONSUMER_KEY;
  const secret = process.env.MPESA_CONSUMER_SECRET;
  
  if (!key || !secret) {
    throw new Error('Missing MPESA_CONSUMER_KEY or MPESA_CONSUMER_SECRET in .env');
  }
  
  const auth = Buffer.from(`${key}:${secret}`).toString('base64');
  const url = 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
  
  try {
    console.log('[MPESA] Requesting token from Safaricom...');
    const r = await axios.get(url, { 
      headers: { 
        Authorization: `Basic ${auth}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });
    console.log('[MPESA] Token received successfully');
    return r.data.access_token;
  } catch (err) {
    console.error('[MPESA] Token request failed:', err.response?.data || err.message);
    throw new Error(`Failed to get M-Pesa token: ${err.message}`);
  }
}

router.post('/stkpush', async (req, res) => {
  try {
    const { phoneNumber, amount, accountReference, description } = req.body;
    
    // Validate required fields
    if (!phoneNumber || !amount || !accountReference) {
      console.log('[MPESA] Missing required fields:', { phoneNumber, amount, accountReference });
      return res.status(400).json({ ok: false, error: 'Missing required fields' });
    }
    
    console.log('[MPESA] STK Push initiated:', { phoneNumber, amount, accountReference });
    
    // Format phone number: remove + and leading 0, ensure it starts with country code
    let formattedPhone = phoneNumber.replace(/^\+/, '').replace(/^0/, '');
    if (!formattedPhone.startsWith('254')) {
      formattedPhone = '254' + formattedPhone;
    }
    console.log('[MPESA] Formatted phone:', formattedPhone);
    
    const token = await getToken();
    const timestamp = new Date().toISOString().replaceAll(/[-:.TZ]/g, '').slice(0, 14);
    const password = Buffer.from(`${process.env.MPESA_SHORTCODE}${process.env.MPESA_PASSKEY}${timestamp}`).toString('base64');

    const payload = {
      BusinessShortCode: process.env.MPESA_SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: Math.round(parseFloat(amount)),
      PartyA: formattedPhone,
      PartyB: process.env.MPESA_SHORTCODE,
      PhoneNumber: formattedPhone,
      CallBackURL: `${process.env.BACKEND_BASE_URL}/api/mpesa/callback`,
      AccountReference: accountReference.toString(),
      TransactionDesc: description || 'Parking fee'
    };

    console.log('[MPESA] Payload:', payload);

    const url = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';
    console.log('[MPESA] Sending request to:', url);
    
    const r = await axios.post(url, payload, { 
      headers: { 
        Authorization: `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      timeout: 10000
    });

    console.log('[MPESA] Response:', r.data);
    
    await db.query('INSERT INTO payments (slot_id, phone, amount, status) VALUES (?,?,?,?)', 
      [accountReference, phoneNumber, amount, 'pending']);

    res.json({ ok: true, data: r.data });
  } catch (err) {
    console.error('[MPESA] STK error:', err.response?.data || err.message);
    console.error('[MPESA] Full error:', err);
    res.status(500).json({ 
      ok: false, 
      error: err.message,
      details: err.response?.data || null
    });
  }
});

router.post('/callback', async (req, res) => {
  try {
    const body = req.body;
    console.log('[MPESA] Callback received:', JSON.stringify(body));
    
    const stk = body.Body?.stkCallback;
    if (!stk) {
      console.log('[MPESA] No STK callback found in request');
      return res.status(200).send({});
    }

    const resultCode = stk.ResultCode;
    const callbackMetadata = stk.CallbackMetadata?.Item || [];

    console.log('[MPESA] Result Code:', resultCode);

    if (resultCode === 0) {
      const receipt = callbackMetadata.find(i => i.Name === 'MpesaReceiptNumber')?.Value;
      const phone = callbackMetadata.find(i => i.Name === 'PhoneNumber')?.Value;
      const amount = callbackMetadata.find(i => i.Name === 'Amount')?.Value;
      
      console.log('[MPESA] Payment successful:', { receipt, phone, amount });
      
      await db.query('UPDATE payments SET status=?, mpesa_receipt=? WHERE phone=? AND status=? ORDER BY created_at DESC LIMIT 1', 
        ['paid', receipt, phone, 'pending']);
      console.log('[MPESA] Payment record updated');
    } else {
      console.log('[MPESA] Payment failed. Result Code:', resultCode, 'Desc:', stk.ResultDesc);
    }

    res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch (err) {
    console.error('[MPESA] Callback error:', err);
    res.status(200).json({ ResultCode: 0, ResultDesc: 'Accepted' });
  }
});

router.get('/test', async (req, res) => {
  try {
    console.log('[MPESA] Running diagnostic test...');
    const diagnostics = {
      timestamp: new Date().toISOString(),
      env: {
        hasConsumerKey: !!process.env.MPESA_CONSUMER_KEY,
        hasConsumerSecret: !!process.env.MPESA_CONSUMER_SECRET,
        hasShortCode: !!process.env.MPESA_SHORTCODE,
        hasPassKey: !!process.env.MPESA_PASSKEY,
        backendBaseUrl: process.env.BACKEND_BASE_URL
      },
      tokenTest: null,
      paymentRecord: null
    };

    try {
      const token = await getToken();
      diagnostics.tokenTest = {
        success: true,
        tokenLength: token.length,
        message: 'Successfully obtained access token'
      };
    } catch (tokenErr) {
      diagnostics.tokenTest = {
        success: false,
        error: tokenErr.message
      };
    }

    try {
      const payments = await db.query('SELECT COUNT(*) as count FROM payments');
      diagnostics.paymentRecord = {
        success: true,
        totalPayments: payments[0]?.count || 0
      };
    } catch (dbErr) {
      diagnostics.paymentRecord = {
        success: false,
        error: dbErr.message
      };
    }

    console.log('[MPESA] Diagnostic result:', diagnostics);
    res.json({ ok: true, diagnostics });
  } catch (err) {
    console.error('[MPESA] Diagnostic error:', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
