# Backend - Local Development

This file describes how to run the Firestore emulator and the Node backend for local development.

Prerequisites
- Node.js (14+)
- npm
- Java (for some Firebase emulator features)

1) Install dev dependencies (one-time):

```powershell
cd backend
npm install
cd ..
npm install --no-audit --no-fund firebase-tools --save-dev
```

2) Start the Firestore emulator (from repo root):

```powershell
npx firebase emulators:start --only firestore --project=smart-parking-dev
```

Emulator UI will be available at `http://localhost:4000` and Firestore emulator at `localhost:8080` by default.

3) Start the backend (in a new terminal)

```powershell
cd backend
# If you want to avoid running the cron while developing locally (recommended):
setx DISABLE_CRON true
# then start the server
node server.js
```

4) Test the API

Use curl/PowerShell/Postman to call endpoints, e.g.:

```powershell
Invoke-RestMethod -Uri 'http://localhost:5000/api/parking/slots' -Method Get
```

Notes
- The backend will connect to the Firestore emulator when `USE_FIRESTORE_EMULATOR=true` is set in `backend/.env`.
- If you need MySQL for production-like testing, run a Docker MySQL and update `.env` accordingly.
Smart Parking Backend
----------------------
Node.js + Express backend for Smart Car Parking System.

Setup:
1. Copy .env.example to .env and fill credentials.
2. npm install
3. Create MySQL database and run sql/schema.sql
4. Place firebase-service-account.json in backend/ (from Firebase console)
5. npm start
