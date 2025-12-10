const express = require('express');
const router = express.Router();
const db = require('../db');
const twilio = require('twilio');
const admin = require('firebase-admin');

let twilioClient = null;
if (process.env.TWILIO_ACCOUNT_SID && process.env.TWILIO_AUTH_TOKEN) {
  twilioClient = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
}

let firestore = null;
if (process.env.USE_FIRESTORE_EMULATOR === 'true') {
  process.env.FIRESTORE_EMULATOR_HOST = process.env.FIRESTORE_EMULATOR_HOST || 'localhost:8080';
  const projectId = process.env.FIREBASE_PROJECT_ID || 'local-dev';
  try {
    if (!admin.apps.length) {
      admin.initializeApp({ projectId });
    }
  } catch (e) {
  }
  firestore = admin.firestore();
} else {
  try {
    if (!admin.apps.length) {
      const serviceAccount = require('../firebase-service-account.json');
      admin.initializeApp({
        credential: admin.credential.cert(serviceAccount),
        databaseURL: process.env.FIREBASE_DB_URL
      });
    }
    firestore = admin.firestore();
  } catch (e) {
  }
}

router.get('/slots', async (req, res) => {
  try {
    const [rows] = await db.execute('SELECT id, name, status, reserved_by, reserved_until, start_time, end_time, plate, phone FROM slots ORDER BY name');
    const slots = rows.map(row => ({
      id: String(row.id),
      name: row.name,
      status: row.status,
      reservedBy: row.reserved_by,
      reservedUntil: row.reserved_until ? new Date(row.reserved_until).toISOString() : null,
      startTime: row.start_time ? new Date(row.start_time).toISOString() : null,
      endTime: row.end_time ? new Date(row.end_time).toISOString() : null,
      plate: row.plate,
      phone: row.phone
    }));
    res.json(slots);
  } catch (err) {
    console.error('Get slots error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.post('/occupy', async (req, res) => {
  try {
    const { slotId, phone, plate } = req.body;
    const now = new Date().toISOString();
    console.log(`[OCCUPY] Slot ${slotId}, phone: ${phone}, plate: ${plate}`);
    await db.execute(
      'UPDATE slots SET status=?, start_time=?, plate=?, phone=? WHERE id=?',
      ['occupied', now, plate || null, phone || null, slotId]
    );
    
    if (firestore) {
      try {
        await firestore.collection('slots').doc(String(slotId)).set({
          status: 'occupied',
          phone: phone || null,
          plate: plate || null,
          start_time: now
        }, { merge: true });
        console.log(`[OCCUPY] Firestore updated for slot ${slotId}`);
      } catch (e) {
        console.warn(`[OCCUPY] Firestore update failed for slot ${slotId}:`, e.message);
      }
    }
    
    res.json({ ok: true });
  } catch (err) {
    console.error('Occupy error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.post('/leave', async (req, res) => {
  try {
    const { slotId } = req.body;
    const now = new Date().toISOString();
    const [rows] = await db.execute('SELECT phone, name, start_time FROM slots WHERE id = ?', [slotId]);
    const slot = (rows && rows[0]) ? rows[0] : null;

    await db.execute(
      'UPDATE slots SET status=?, end_time=?, plate=NULL, phone=NULL WHERE id=?',
      ['available', now, slotId]
    );

    const simulateSms = process.env.SIMULATE_SMS === 'true';
    if (simulateSms && slot && slot.phone) {
      console.log('[SIMULATED SMS] To:', slot.phone, 'Message:', `Your parking session for slot ${slot.name || slotId} has ended at ${now}. Thank you.`);
    } else if (twilioClient && slot && slot.phone) {
      try {
        const message = `Your parking session for slot ${slot.name || slotId} has ended at ${now}. Thank you.`;
        await twilioClient.messages.create({ body: message, from: process.env.TWILIO_PHONE_NUMBER, to: slot.phone });
      } catch (e) {
        console.warn('Twilio send failed on leave:', e.message);
      }
    } else if (!twilioClient) {
      console.log('Twilio not configured; skipping leave SMS');
    }

    res.json({ ok: true });
  } catch (err) {
    console.error('Leave error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
