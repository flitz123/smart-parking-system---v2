const express = require('express');
const router = express.Router();
const db = require('../db');
const twilio = require('twilio');
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');


if (process.env.USE_FIRESTORE_EMULATOR === 'true') {
  process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
  const projectId = process.env.FIREBASE_PROJECT_ID || 'local-dev';
  try {
    if (!admin.apps.length) {
      admin.initializeApp({ projectId });
    }
    console.log('Using Firestore emulator at', process.env.FIRESTORE_EMULATOR_HOST);
  } catch (e) {
    console.warn('Failed to init Firebase Admin for emulator:', e.message || e);
  }
} else {
  if (!admin.apps.length) {
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
      databaseURL: process.env.FIREBASE_DB_URL
    });
  }
}
const firestore = admin.firestore();

let twilioClient = null;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
  twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

router.post('/reserve', async (req, res) => {
  try {
    const { slotId, phone, plate, durationMinutes } = req.body;
    const duration = durationMinutes ? parseInt(durationMinutes) : 60;
    if (phone) {
      console.log('Checking existing reservation for phone:', phone);
      const [existing] = await db.query('SELECT * FROM slots WHERE reserved_by = ? AND status = ? LIMIT 1', [phone, 'reserved']);
      if (existing.length > 0) return res.status(400).json({ ok: false, message: 'You already have an active reservation' });
    }

    console.log('Selecting slot by id:', slotId);
    const [rows] = await db.query('SELECT * FROM slots WHERE id = ? LIMIT 1', [slotId]);
  if (rows.length === 0) return res.status(404).json({ ok: false, message: 'Slot not found' });
  if (!(rows[0].status === 'available' || rows[0].status === 'empty')) return res.status(400).json({ ok: false, message: 'Slot not available' });

    const reservedUntil = new Date(Date.now() + duration * 60000);
  const reservedUntilIso = reservedUntil.toISOString();
  console.log('Updating slot', slotId, 'with reservedUntil', reservedUntilIso, 'phone', phone, 'plate', plate);
  await db.query('UPDATE slots SET status=?, reserved_until=?, reserved_by=?, plate=?, phone=? WHERE id=?', ['reserved', reservedUntilIso, phone, plate || null, phone || null, slotId]);

    await firestore.collection('slots').doc(String(slotId)).set({
      status: 'reserved',
      reserved_by: phone,
      reserved_until: reservedUntilIso
    }, { merge: true });

    const message = `Reservation confirmed for slot ${slotId}. Expires at ${reservedUntil.toISOString()}.`;
    const simulateSms = process.env.SIMULATE_SMS === 'true';
    if (simulateSms) {
      console.log('[SIMULATED SMS] To:', phone, 'Message:', message);
    } else if (twilioClient) {
      try {
        await twilioClient.messages.create({ body: message, from: process.env.TWILIO_PHONE_NUMBER, to: phone });
      } catch (e) {
        console.warn('Twilio send failed:', e.message);
      }
    } else {
      console.log('Twilio not configured, skipping SMS. Message would be:', message);
    }

    res.json({ ok: true, message: 'Reserved', reservedUntil: reservedUntil.toISOString() });
  } catch (err) {
    console.error('Reserve error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.post('/cancel', async (req, res) => {
  try {
    const { slotId, phone } = req.body;
  await db.query('UPDATE slots SET status=?, reserved_by=NULL, reserved_until=NULL, plate=NULL, phone=NULL WHERE id=?', ['available', slotId]);


    try {
      await firestore.collection('slots').doc(String(slotId)).update({
        status: 'available',
        reserved_by: admin.firestore.FieldValue.delete(),
        reserved_until: admin.firestore.FieldValue.delete()
      });
    } catch (e) {
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('Cancel error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
