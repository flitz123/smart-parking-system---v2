const express = require('express');
const router = express.Router();
const twilio = require('twilio');
require('dotenv').config();

const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

router.post('/send', async (req, res) => {
  try {
    const { phoneNumber, message } = req.body;
    const m = await client.messages.create({ body: message, from: process.env.TWILIO_PHONE_NUMBER, to: phoneNumber });
    res.json({ ok: true, sid: m.sid });
  } catch (err) {
    console.error('Twilio send error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
