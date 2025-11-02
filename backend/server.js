const express = require('express');
const bodyParser = require('body-parser');
const cors = require('cors');
require('dotenv').config();

const reservationRoutes = require('./routes/reservations');
const twilioRoutes = require('./routes/twilio');
const mpesaRoutes = require('./routes/mpesa');
const parkingRoutes = require('./routes/parking');

const app = express();
app.use(cors());
app.use(bodyParser.json());

app.use('/api/reservations', reservationRoutes);
app.use('/api/twilio', twilioRoutes);
app.use('/api/mpesa', mpesaRoutes);
app.use('/api/parking', parkingRoutes);

app.get('/health', (req, res) => res.json({ ok: true }));

const PORT = process.env.PORT || 5000;
app.listen(PORT, () => console.log(`Server listening on port ${PORT}`));

// start cron
require('./cron');
