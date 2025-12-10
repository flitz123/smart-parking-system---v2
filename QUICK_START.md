# 🚀 Quick Start - Payment Testing Guide

## Prerequisites
✅ All required files have been updated with improved payment handling
✅ ngrok auth token is in `.env` file

## One-Time Setup (First Time Only)

### 1. Download and Install ngrok
- Go to https://ngrok.com/download
- Download for Windows
- Extract and add to PATH, or run installer

**Verify installation:**
```powershell
ngrok --version
# Output: ngrok version X.X.X
```

## Running the Application

### Terminal 1: Start ngrok (MUST START FIRST)
```powershell
# From project root
.\setup-ngrok.ps1
```

**What this does:**
- Verifies ngrok installation
- Checks auth token in .env
- Starts ngrok tunnel on port 5000
- Automatically updates .env with public URL
- Shows the public URL

**Expected output:**
```
✅ ngrok tunnel established!

📍 Public URL: https://xxxx-xxxx-xxxx-xxxx.ngrok.io

Next steps:
  1. In another terminal, start the backend:
     cd backend
     node server.js

  2. In another terminal, start the Flutter app:
     cd flutter_app
     flutter run -d chrome

🔗 ngrok dashboard: http://localhost:4040

⚠️  Keep this terminal open - ngrok needs to stay running!
Press Ctrl+C to stop ngrok...
```

**IMPORTANT:** Keep this terminal open while testing!

---

### Terminal 2: Start Backend Server
```powershell
# Open NEW terminal, from project root
cd backend
node server.js
```

**Expected output:**
```
[MPESA] Requesting token from Safaricom...
[MPESA] Token received successfully
...
Server listening on 0.0.0.0:5000
```

**Verify backend is running:**
In another terminal (Terminal 4):
```powershell
curl http://localhost:5000/api/mpesa/test
```

---

### Terminal 3: Start Flutter App
```powershell
# Open NEW terminal, from project root
cd flutter_app
flutter run -d chrome
```

**Expected output:**
```
Launching lib/main.dart on Chrome in debug mode...
...
Application finished.
```

Flutter web app opens in Chrome → You're ready to test!

---

## Testing Payment Flow

### Step 1: Occupy a Parking Slot
1. Open the Flutter app in Chrome (should auto-open)
2. Click on an available green slot (e.g., "A1")
3. Enter:
   - **Phone**: `+254712345678`
   - **Plate**: `KAA123A`
4. Click **"Assign & Send SMS"**
5. Slot should turn red (occupied)

### Step 2: Test Payment
1. Click the **red occupied slot** to see details
2. Click **"View Details"** button
3. Click **"Pay"** button in the dialog
4. You should see the message: **"Processing payment..."**

### Step 3: Monitor Backend Logs
Watch Terminal 2 (backend) for logs like:
```
[MPESA] STK Push initiated: { phoneNumber: '+254712345678', amount: '...', accountReference: '1' }
[MPESA] Formatted phone: 254110596134
[MPESA] Requesting token from Safaricom...
[MPESA] Token received successfully
[MPESA] Payload: { ... }
[MPESA] Sending request to: https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest
[MPESA] Response: { ResponseCode: "0", ResponseDescription: "Accept the service request successfully." }
```

### Step 4: Expected Results
- ✅ **Success**: Flutter shows green snackbar "M-Pesa prompt sent successfully"
- ❌ **Error**: Shows red snackbar with error details (see troubleshooting below)

---

## Troubleshooting

### ❌ "Invalid CallBackURL"
**Cause**: ngrok not running or .env not updated
**Fix**:
```powershell
# Make sure Terminal 1 (ngrok) is still running
# Check if .env has correct BACKEND_BASE_URL
cat backend\.env | grep BACKEND_BASE_URL
```

### ❌ "System is busy. Please try again..."
**Cause**: Safaricom sandbox overload (temporary)
**Fix**: Wait 2 minutes and retry

### ❌ "Network error: ..."
**Cause**: Backend server not running
**Fix**:
```powershell
# Check if backend is running
netstat -an | findstr :5000
# If not running, start Terminal 2: cd backend && node server.js
```

### ❌ ngrok script fails to run
**Cause**: PowerShell execution policy
**Fix**:
```powershell
# Run PowerShell as Administrator, then:
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### ❌ "NGROK_AUTHTOKEN not found in .env"
**Cause**: Token not in .env file
**Fix**:
1. Add to `backend/.env`:
   ```env
   NGROK_AUTHTOKEN=your_token_here
   ```
2. Rerun setup-ngrok.ps1

---

## Monitoring Payment Flow

### ngrok Dashboard
While testing, open http://localhost:4040 in browser to see:
- All HTTP requests made through the tunnel
- Request/response bodies
- Headers and timing

### Backend Logs
All payment events are logged with `[MPESA]` prefix for easy filtering:
```
[MPESA] STK Push initiated
[MPESA] Token received
[MPESA] Payload
[MPESA] Sending request
[MPESA] Response
[MPESA] Payment record updated
```

### Flutter Logs
Console output shows with `[API]` prefix:
```
[API] Initiating M-Pesa STK push
[API] M-Pesa response status: 200
[API] M-Pesa response body: {...}
```

---

## File Changes Summary

### Modified Files:
1. **`backend/routes/mpesa.js`**
   - Enhanced token retrieval with detailed logging
   - Improved phone formatting (removes +, leading 0)
   - Amount validation and rounding
   - Better error messages
   - Added `/test` diagnostic endpoint

2. **`flutter_app/lib/services/api_service.dart`**
   - Returns error details (was just bool)
   - Logs all requests/responses
   - Better error handling

3. **`flutter_app/lib/screens/grid_screen.dart`**
   - Shows error details in snackbars
   - Colored feedback (green=success, red=error)
   - Auto-refresh after successful payment

### New Files:
1. **`setup-ngrok.ps1`**
   - Automated ngrok setup script
   - Updates .env with public URL

2. **`PAYMENT_SETUP.md`**
   - Complete payment integration guide

3. **`QUICK_START.md`** (this file)
   - Step-by-step testing instructions

---

## Environment Variables

Your `.env` now has all required fields:

```env
# Safaricom M-Pesa (from Developer Portal)
MPESA_CONSUMER_KEY=zhGO5a65NJGrUcuS9Tb9spSZGwgk43gRjq94wneIBzlpyGAO
MPESA_CONSUMER_SECRET=APQGDVkWjIiAMjlcd2SIdFcESmXxNfYgaV3BC05Eb3GGWO0go3ZnfSchdLtrufmt
MPESA_SHORTCODE=174379
MPESA_PASSKEY=bfb279f9aa9bdbcf158e97dd71a467cd2e0c893059b10f78e6b72ada1ed2c919

# ngrok tunnel (auto-updated by setup-ngrok.ps1)
BACKEND_BASE_URL=https://xxxx-xxxx-xxxx-xxxx.ngrok.io
NGROK_AUTHTOKEN=your_auth_token

# Twilio SMS
TWILIO_ACCOUNT_SID=ACe4b808c00908e530d23d33c7e47adbdc
TWILIO_AUTH_TOKEN=5c94532dd50c833fe33b57939d4ec750
TWILIO_PHONE_NUMBER=+254110596134
```

---

## Next Steps After Testing

### ✅ If Payment Works Locally:
1. Test multiple payments to ensure consistency
2. Monitor callback handling in backend logs
3. Verify SMS notifications are sent

### 🚀 For Production:
1. Replace `MPESA_CONSUMER_KEY` and `MPESA_CONSUMER_SECRET` with production credentials
2. Replace `BACKEND_BASE_URL` with your production domain (no ngrok needed)
3. Use production Safaricom endpoints (not sandbox)
4. Deploy backend to a public server

---

## Support

For detailed information about:
- Payment integration: See `PAYMENT_SETUP.md`
- API endpoints: See `PAYMENT_SETUP.md` → API Endpoints section
- Error codes: See `PAYMENT_SETUP.md` → Troubleshooting table

---

**Happy testing! 🎉**
