const cron = require('node-cron');
const db = require('./db');
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount), databaseURL: process.env.FIREBASE_DB_URL });
}
const firestore = admin.firestore();

// run every 5 minutes
cron.schedule('*/5 * * * *', async () => {
  try {
    const [rows] = await db.query("SELECT id FROM slots WHERE status='reserved' AND reserved_until < NOW()");
    if (rows.length > 0) {
      const ids = rows.map(r => r.id);
      await db.query("UPDATE slots SET status='empty', reserved_by=NULL, reserved_until=NULL, plate=NULL, phone=NULL WHERE status='reserved' AND reserved_until < NOW()");
      for (const id of ids) {
        await firestore.collection('slots').doc(String(id)).update({
          status: 'empty',
          reserved_by: admin.firestore.FieldValue.delete(),
          reserved_until: admin.firestore.FieldValue.delete()
        });
      }
      console.log(`Released ${ids.length} expired reservations`);
    }
  } catch (err) {
    console.error('Cron error', err);
  }
});

console.log('Cron job started: check reservations every 5 minutes');