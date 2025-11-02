const express = require('express');
const router = express.Router();
const db = require('../db');
const admin = require('firebase-admin');
const serviceAccount = require('../firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    databaseURL: process.env.FIREBASE_DB_URL
  });
}
const firestore = admin.firestore();

router.post('/occupy', async (req, res) => {
  try {
    const { slotId, phone, plate } = req.body;
    await db.query('UPDATE slots SET status=?, start_time=NOW(), plate=?, phone=? WHERE id=?', ['occupied', plate || null, phone || null, slotId]);
    await firestore.collection('slots').doc(String(slotId)).update({
      status: 'occupied',
      start_time: new Date().toISOString()
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Occupy error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

router.post('/leave', async (req, res) => {
  try {
    const { slotId } = req.body;
    await db.query('UPDATE slots SET status=?, end_time=NOW(), plate=NULL, phone=NULL WHERE id=?', ['empty', slotId]);
    await firestore.collection('slots').doc(String(slotId)).update({
      status: 'empty',
      start_time: admin.firestore.FieldValue.delete()
    });
    res.json({ ok: true });
  } catch (err) {
    console.error('Leave error', err);
    res.status(500).json({ ok: false, error: err.message });
  }
});

module.exports = router;
