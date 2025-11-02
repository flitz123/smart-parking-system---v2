const express = require('express');
const axios = require('axios');
const db = require('../db');
require('dotenv').config();

const router = express.Router();

async function getToken() {
  const key = process.env.MPESA_CONSUMER_KEY;
  const secret = process.env.MPESA_CONSUMER_SECRET;
  const auth = Buffer.from(`${key}:${secret}`).toString('base64');
  const url = 'https://sandbox.safaricom.co.ke/oauth/v1/generate?grant_type=client_credentials';
  const r = await axios.get(url, { headers: { Authorization: `Basic ${auth}` } });
  return r.data.access_token;
}

router.post('/stkpush', async (req, res) => {
  try {
    const { phoneNumber, amount, accountReference, description } = req.body;
    const token = await getToken();
    const timestamp = new Date().toISOString().replace(/[-:.TZ]/g, '').slice(0, 14);
    const password = Buffer.from(`${process.env.MPESA_SHORTCODE}${process.env.MPESA_PASSKEY}${timestamp}`).toString('base64');

    const payload = {
      BusinessShortCode: process.env.MPESA_SHORTCODE,
      Password: password,
      Timestamp: timestamp,
      TransactionType: 'CustomerPayBillOnline',
      Amount: amount,
      PartyA: phoneNumber.replace('+',''),
      PartyB: process.env.MPESA_SHORTCODE,
      PhoneNumber: phoneNumber.replace('+',''),
      CallBackURL: `${process.env.BACKEND_BASE_URL}/api/mpesa/callback`,
      AccountReference: accountReference,
      TransactionDesc: description
    };

    const url = 'https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest';
    const r = await axios.post(url, payload, { headers: { Authorization: `Bearer ${token}` } });

    await db.query('INSERT INTO payments (slot_id, phone, amount, status) VALUES (?,?,?,?)', [accountReference, phoneNumber, amount, 'pending']);

    res.json({ ok: true, data: r.data });
  } catch (err) {
    console.error('STK error', err.response?.data || err.message);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.post('/callback', async (req, res) => {
  try {
    const body = req.body;
    const stk = body.Body?.stkCallback;
    if (!stk) return res.status(200).send({});

    const resultCode = stk.ResultCode;
    const callbackMetadata = stk.CallbackMetadata?.Item || [];

    if (resultCode === 0) {
      const receipt = callbackMetadata.find(i => i.Name === 'MpesaReceiptNumber')?.Value;
      const amount = callbackMetadata.find(i => i.Name === 'Amount')?.Value;
      const phone = callbackMetadata.find(i => i.Name === 'PhoneNumber')?.Value;

      await db.query('UPDATE payments SET status=?, mpesa_receipt=? WHERE phone=? AND status=? ORDER BY created_at DESC LIMIT 1', ['paid', receipt, phone, 'pending']);
    } else {
      console.log('Payment failed', stk.ResultDesc);
    }

    res.json({ ResultCode: 0, ResultDesc: 'Accepted' });
  } catch (err) {
    console.error('Callback error', err);
    res.status(500).json({ error: err.message });
  }
});

module.exports = router;
