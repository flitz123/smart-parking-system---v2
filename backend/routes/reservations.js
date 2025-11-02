const express = require('express');
const router = express.Router();
const db = require('../db');
const twilio = require('twilio');
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DB_URL
  });
}
const firestore = admin.firestore();

const twilioClient = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);

router.post('/reserve', async (req, res) => {
  try {
    const { slotId, phone, plate, durationMinutes } = req.body;
    const duration = durationMinutes ? parseInt(durationMinutes) : 60;
    // check existing reservation by phone
    const [existing] = await db.query('SELECT * FROM slots WHERE reserved_by = ? AND status = ? LIMIT 1', [phone, 'reserved']);
    if (existing.length > 0) return res.status(400).json({ ok: false, message: 'You already have an active reservation' });

    const [rows] = await db.query('SELECT * FROM slots WHERE id = ? LIMIT 1', [slotId]);
    if (rows.length === 0) return res.status(404).json({ ok: false, message: 'Slot not found' });
    if (rows[0].status !== 'empty') return res.status(400).json({ ok: false, message: 'Slot not available' });

    const reservedUntil = new Date(Date.now() + duration * 60000);
    await db.query('UPDATE slots SET status=?, reserved_until=?, reserved_by=?, plate=?, phone=? WHERE id=?', ['reserved', reservedUntil, phone, plate || null, phone || null, slotId]);

    // update firestore
    await firestore.collection('slots').doc(String(slotId)).set({
      status: 'reserved',
      reserved_by: phone,
      reserved_until: reservedUntil.toISOString()
    }, { merge: true });

    // send twilio sms
    const message = `Reservation confirmed for slot ${slotId}. Expires at ${reservedUntil.toISOString()}.`;
    await twilioClient.messages.create({ body: message, from: process.env.TWILIO_PHONE_NUMBER, to: phone });

    res.json({ ok: true, message: 'Reserved', reservedUntil: reservedUntil.toISOString() });
  } catch (err) {
    console.error('Reserve error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.post('/cancel', async (req, res) => {
  try {
    const { slotId, phone } = req.body;
    await db.query('UPDATE slots SET status=?, reserved_by=NULL, reserved_until=NULL, plate=NULL, phone=NULL WHERE id=?', ['empty', slotId]);

    // update firestore
    await firestore.collection('slots').doc(String(slotId)).update({
      status: 'empty',
      reserved_by: admin.firestore.FieldValue.delete(),
      reserved_until: admin.firestore.FieldValue.delete()
    });

    res.json({ ok: true });
  } catch (err) {
    console.error('Cancel error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
