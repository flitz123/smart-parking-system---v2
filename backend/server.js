const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config();

const parkingRoutes = require('./routes/parking');

let reservationRoutes, twilioRoutes, mpesaRoutes;
try {
  reservationRoutes = require('./routes/reservations');
} catch (e) {
  console.warn('⚠ Reservations route not available');
}
try {
  twilioRoutes = require('./routes/twilio');
} catch (e) {
  console.warn('⚠ Twilio route not available');
}
try {
  mpesaRoutes = require('./routes/mpesa');
} catch (e) {
  console.warn('⚠ M-Pesa route not available');
}

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use('/api/parking', parkingRoutes);
if (reservationRoutes) app.use('/api/reservations', reservationRoutes);
if (twilioRoutes) app.use('/api/twilio', twilioRoutes);
if (mpesaRoutes) app.use('/api/mpesa', mpesaRoutes);

app.get('/health', (req, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 5000;
const HOST = process.env.HOST || '0.0.0.0';
app.listen(PORT, HOST, () => console.log(`✓ Server listening on ${HOST}:${PORT}`));

try {
  if (!process.env.DISABLE_CRON) {
    require('./cron');
  } else {
    console.log('Cron disabled via DISABLE_CRON=true');
  }
} catch (e) {
  console.warn('⚠ Cron job not available');
}
