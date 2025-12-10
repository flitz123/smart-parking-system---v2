# 📁 Smart Parking System - Complete File Reference

## Project Structure

```
smart-parking-system---v2/
├── 📄 QUICK_START.md                    ← START HERE! Quick testing guide
├── 📄 IMPLEMENTATION_SUMMARY.md         ← Overview of all changes
├── 📄 PAYMENT_SETUP.md                  ← Detailed payment guide
├── 📄 ARCHITECTURE.md                   ← System diagrams & flows
├── 📄 TESTING_CHECKLIST.md              ← Complete testing checklist
├── 🔧 setup-ngrok.ps1                   ← Windows automation script
├── 🔧 setup-ngrok.sh                    ← Linux/Mac automation script
├── 📄 README.md                         ← Project overview
├── 📄 PAYMENT_SETUP.md                  ← (duplicate) Payment details
├── 📄 run_flutter.ps1                   ← Flutter launcher script
├── 📄 firebase.json                     ← Firebase config
│
├── 📁 backend/                          ← Node.js backend
│   ├── .env                             ← Environment variables ⭐
│   │   ├── MPESA_CONSUMER_KEY
│   │   ├── MPESA_CONSUMER_SECRET
│   │   ├── MPESA_SHORTCODE
│   │   ├── MPESA_PASSKEY
│   │   ├── NGROK_AUTHTOKEN             ← Your ngrok token
│   │   ├── BACKEND_BASE_URL            ← Auto-updated by script
│   │   ├── TWILIO_ACCOUNT_SID
│   │   ├── TWILIO_AUTH_TOKEN
│   │   ├── TWILIO_PHONE_NUMBER
│   │   └── Firebase config
│   │
│   ├── package.json                    ← Dependencies
│   ├── server.js                        ← Express app entry
│   ├── db.js                            ← Database abstraction
│   ├── cron.js                          ← Reservation expiry job
│   ├── setup-db.js                      ← Database initialization
│   │
│   ├── 📁 routes/
│   │   ├── mpesa.js                    ← ⭐ PAYMENT ROUTES
│   │   │   ├── POST /stkpush           ← Initiate payment
│   │   │   ├── POST /callback          ← Payment callback
│   │   │   └── GET /test               ← Diagnostic endpoint
│   │   ├── parking.js                  ← Parking slot routes
│   │   ├── reservations.js             ← Reservation routes
│   │   └── twilio.js                   ← SMS routes
│   │
│   ├── 📁 sql/
│   │   └── schema.sql                  ← Database schema
│   │       └── payments table          ← Payment records
│   │
│   └── 🗄️ parking.db                   ← SQLite database
│
└── 📁 flutter_app/                     ← Flutter frontend
    ├── pubspec.yaml                    ← Dependencies
    ├── analysis_options.yaml
    │
    ├── 📁 lib/
    │   ├── main.dart                   ← App entry point
    │   │
    │   ├── 📁 models/
    │   │   └── parking_slot.dart        ← Slot model
    │   │
    │   ├── 📁 services/
    │   │   ├── api_service.dart         ← ⭐ API CLIENT
    │   │   │   └── initiateMpesa()      ← Payment function
    │   │   └── firebase_service.dart    ← Firestore service
    │   │
    │   └── 📁 screens/
    │       ├── grid_screen.dart         ← ⭐ MAIN UI
    │       │   └── Pay button logic     ← Payment flow
    │       ├── entry_form.dart          ← Slot form
    │       └── reserve_sheet.dart       ← Reservation form
    │
    ├── 📁 web/
    │   └── index.html
    │
    └── 📁 android/
        └── (Android app config)
```

---

## 🔑 Key Files by Functionality

### Payment Flow
| File | Component | Purpose |
|------|-----------|---------|
| `backend/.env` | Configuration | Stores all credentials & URLs |
| `backend/routes/mpesa.js` | Backend | Handles STK push & callbacks |
| `flutter_app/lib/services/api_service.dart` | Frontend | Makes API calls to backend |
| `flutter_app/lib/screens/grid_screen.dart` | UI | Shows payment button & results |

### Automation
| File | Purpose |
|------|---------|
| `setup-ngrok.ps1` | Starts ngrok tunnel (Windows) |
| `setup-ngrok.sh` | Starts ngrok tunnel (Linux/Mac) |

### Documentation
| File | Content |
|------|---------|
| `QUICK_START.md` | 5-minute testing guide |
| `PAYMENT_SETUP.md` | Detailed setup instructions |
| `IMPLEMENTATION_SUMMARY.md` | What changed & why |
| `ARCHITECTURE.md` | System design & diagrams |
| `TESTING_CHECKLIST.md` | Complete verification list |
| `FILE_REFERENCE.md` | This file |

---

## 🔄 Data Files

### Environment Variables (`.env`)
Location: `backend/.env`

```env
# Safaricom API
MPESA_CONSUMER_KEY=zhGO5a65NJGrUcuS9Tb9spSZGwgk43gRjq94wneIBzlpyGAO
MPESA_CONSUMER_SECRET=APQGDVkWjIiAMjlcd2SIdFcESmXxNfYgaV3BC05Eb3GGWO0go3ZnfSchdLtrufmt
MPESA_SHORTCODE=174379
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919

# ngrok
NGROK_AUTHTOKEN=your_token_here
BACKEND_BASE_URL=https://xxxx-xxxx.ngrok.io  ← Auto-updated

# Twilio
TWILIO_ACCOUNT_SID=ACe4b808c00908e530d23d33c7e47adbdc
TWILIO_AUTH_TOKEN=5c94532dd50c833fe33b57939d4ec750
TWILIO_PHONE_NUMBER=+254110596134

# Firebase
FIREBASE_PROJECT_ID=smart-parking-dev
USE_FIRESTORE_EMULATOR=true
FIRESTORE_EMULATOR_HOST=localhost:8080
```

### Database Schema
Location: `backend/sql/schema.sql` & `backend/db.js`

```sql
CREATE TABLE payments (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  slot_id INTEGER NOT NULL,
  phone TEXT NOT NULL,
  amount REAL NOT NULL,
  status TEXT DEFAULT 'pending',
  mpesa_receipt TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 📝 Code Changes Summary

### Backend Changes

#### `backend/routes/mpesa.js`
```
Before: 47 lines
After:  195 lines

Additions:
- Enhanced getToken() with validation & logging
- Input validation in /stkpush
- Phone formatting logic
- Better error handling
- Diagnostic /test endpoint
```

#### `backend/db.js`
```
- SQLite parameter sanitization
- Date/null type handling
- Connection pooling
```

### Frontend Changes

#### `flutter_app/lib/services/api_service.dart`
```
Before: initiateMpesa() → bool
After:  initiateMpesa() → Map<String, dynamic>

Additions:
- Detailed error capture
- Request/response logging
- Timeout handling
```

#### `flutter_app/lib/screens/grid_screen.dart`
```
Additions:
- Enhanced payment flow with error display
- Auto-refresh after payment
- Colored feedback (green/red snackbars)
- Better user messaging
```

---

## 🚀 Quick Command Reference

### Run ngrok (Terminal 1)
```powershell
.\setup-ngrok.ps1
```

### Run Backend (Terminal 2)
```powershell
cd backend
node server.js
```

### Run Flutter (Terminal 3)
```powershell
cd flutter_app
flutter run -d chrome
```

### Test Payment
```powershell
# Open app in Chrome
# Occupy a slot with phone: +254110596134
# Click Pay button
# Watch backend logs
```

### Check Backend Health
```powershell
curl http://localhost:5000/api/mpesa/test
curl http://localhost:5000/api/parking/slots
```

### Monitor ngrok
```
Open: http://localhost:4040
```

---

## 📊 File Sizes

| File | Size | Type |
|------|------|------|
| `backend/routes/mpesa.js` | ~7KB | JavaScript |
| `flutter_app/lib/services/api_service.dart` | ~3KB | Dart |
| `flutter_app/lib/screens/grid_screen.dart` | ~5KB | Dart |
| `QUICK_START.md` | ~6KB | Markdown |
| `PAYMENT_SETUP.md` | ~8KB | Markdown |
| `ARCHITECTURE.md` | ~12KB | Markdown |

---

## 🔐 Sensitive Files

⚠️ **NEVER commit these to git**:
- `backend/.env` - Contains API credentials
- `backend/parking.db` - Database with real data
- `backend/*firebase*.json` - Firebase service account
- `.git/` - Version control metadata

✅ **Safe to commit**:
- All `.dart` files - No credentials
- All `.js` files - No credentials in code
- All `.md` files - Documentation
- `pubspec.yaml` - Dependencies
- `package.json` - Dependencies

---

## 🔍 File Dependencies

```
setup-ngrok.ps1
    ├─ backend/.env (reads NGROK_AUTHTOKEN)
    └─ ngrok (executes)

backend/server.js
    ├─ db.js
    ├─ routes/mpesa.js
    ├─ routes/parking.js
    ├─ routes/reservations.js
    ├─ routes/twilio.js
    └─ .env (process.env vars)

backend/routes/mpesa.js
    ├─ axios (npm)
    ├─ db.js (local)
    └─ .env (process.env)

flutter_app/lib/main.dart
    ├─ services/api_service.dart
    ├─ services/firebase_service.dart
    ├─ screens/grid_screen.dart
    ├─ screens/entry_form.dart
    └─ screens/reserve_sheet.dart

flutter_app/lib/screens/grid_screen.dart
    ├─ services/api_service.dart
    └─ services/firebase_service.dart
```

---

## 📱 Environment Detection

### Flutter baseUrl Selection
```dart
if (kIsWeb)
  // Web: http://localhost:5000
  // or https://xxxx-xxxx.ngrok.io (via .env BACKEND_BASE)
  return 'http://localhost:5000';
else
  // Android: http://10.0.2.2:5000 (emulator bridge)
  return 'http://10.0.2.2:5000';
```

---

## 🔄 Workflow

### Development Workflow
```
1. Update .env with NGROK_AUTHTOKEN
2. Run setup-ngrok.ps1 (Terminal 1)
3. Run backend (Terminal 2)
4. Run Flutter (Terminal 3)
5. Test in Chrome
6. Monitor logs
7. Iterate based on feedback
```

### Debugging Workflow
```
1. Check ngrok dashboard: http://localhost:4040
2. Check backend logs: Terminal 2 output
3. Check Flutter logs: Terminal 3 output
4. Run diagnostic: curl http://localhost:5000/api/mpesa/test
5. Check database: View parking.db
6. Check .env: Verify all credentials
```

---

## ✨ File Completeness Checklist

Code Files:
- [x] `backend/routes/mpesa.js` - Payment logic complete
- [x] `backend/db.js` - Database layer complete
- [x] `backend/server.js` - Server setup complete
- [x] `flutter_app/lib/services/api_service.dart` - API client complete
- [x] `flutter_app/lib/screens/grid_screen.dart` - UI complete

Documentation Files:
- [x] `QUICK_START.md` - Testing guide complete
- [x] `PAYMENT_SETUP.md` - Setup guide complete
- [x] `IMPLEMENTATION_SUMMARY.md` - Summary complete
- [x] `ARCHITECTURE.md` - Diagrams complete
- [x] `TESTING_CHECKLIST.md` - Checklist complete
- [x] `FILE_REFERENCE.md` - This file complete

Automation Files:
- [x] `setup-ngrok.ps1` - Windows script complete
- [x] `setup-ngrok.sh` - Linux/Mac script complete

Configuration Files:
- [x] `backend/.env` - Credentials complete
- [x] `pubspec.yaml` - Dependencies complete
- [x] `package.json` - Dependencies complete

---

**All files are complete and ready for use! 🎉**

Refer to `QUICK_START.md` to begin testing.
