const cron = require('node-cron');
const db = require('./db');
const admin = require('firebase-admin');
const serviceAccount = require('./firebase-service-account.json');

if (!admin.apps.length) {
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount), databaseURL: process.env.FIREBASE_DB_URL });
}
const firestore = admin.firestore();

cron.schedule('*/5 * * * *', async () => {
  try {
    const now = new Date();
    const [rows] = await db.query("SELECT id, reserved_until FROM slots WHERE status='reserved'");
    const expiredIds = rows.filter(r => new Date(r.reserved_until) < now).map(r => r.id);
    
    if (expiredIds.length > 0) {
      await db.query(
        "UPDATE slots SET status='empty', reserved_by=NULL, reserved_until=NULL, plate=NULL, phone=NULL WHERE id IN (" + expiredIds.join(',') + ")"
      );
      for (const id of expiredIds) {
        await firestore.collection('slots').doc(String(id)).update({
          status: 'empty',
          reserved_by: admin.firestore.FieldValue.delete(),
          reserved_until: admin.firestore.FieldValue.delete()
        });
      }
      console.log(`Released ${expiredIds.length} expired reservations`);
    }
  } catch (err) {
    console.error('Cron error', err);
  }
});

console.log('Cron job started: check reservations every 5 minutes');