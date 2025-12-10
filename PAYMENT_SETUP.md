# M-Pesa Payment Integration Guide

## Current Issues & Solutions

### 1. **CallbackURL Validation Error** (400.002.02)
**Problem**: Safaricom sandbox rejects localhost URLs as callback endpoints. The error is:
```
errorCode: '400.002.02'
errorMessage: 'Bad Request - Invalid CallBackURL'
```

**Root Cause**: Safaricom's sandbox requires a publicly accessible URL for callbacks. `http://localhost:5000` is not reachable from the internet.

**Solutions**:

#### Option A: Use ngrok (Recommended for Development)
1. Install ngrok: https://ngrok.com/download
2. Expose your local backend to the internet:
   ```bash
   ngrok http 5000
   ```
3. This gives you a public URL like `https://xxxx-xx-xxx-xx-x.ngrok.io`
4. Update `.env`:
   ```env
   BACKEND_BASE_URL=https://xxxx-xx-xxx-xx-x.ngrok.io
   ```

#### Option B: Use Staging Server
Deploy your backend to a staging server with a public domain, then update:
```env
BACKEND_BASE_URL=https://your-staging-domain.com
```

#### Option C: Test with Mock Callback
For development without real callbacks, temporarily set callback to a dummy HTTPS URL (Safaricom won't call it):
```env
BACKEND_BASE_URL=https://example.com
```
> **Note**: Real payment confirmations won't work until you have a proper public callback endpoint.

### 2. **System Busy Error** (500.003.02)
**Problem**: Intermittent "System is busy. Please try again in few minutes" response.

**Solution**: Implement automatic retry logic with exponential backoff (code is already in place):
```javascript
// Backend will log [MPESA] error and return details to frontend
// Frontend displays error and allows user to retry
```

### 3. **Phone Number Formatting**
**Current Implementation**: 
- Removes `+` prefix
- Removes leading `0`
- Ensures 254 country code
- Example: `+254712345678` → `254712345678` ✓

### 4. **Amount Formatting**
**Current Implementation**:
- Converts to integer (KES is currency without decimals)
- Example: `1140.83` → `1141` ✓

---

## Testing Payment Flow

### Step 1: Start Backend with Diagnostic Check
```bash
cd backend
node server.js
```

### Step 2: Run Diagnostic Test
```bash
curl http://localhost:5000/api/mpesa/test
```

Expected response:
```json
{
  "ok": true,
  "diagnostics": {
    "env": {
      "hasConsumerKey": true,
      "hasConsumerSecret": true,
      "hasShortCode": true,
      "hasPassKey": true,
      "backendBaseUrl": "http://localhost:5000"
    },
    "tokenTest": {
      "success": true,
      "tokenLength": 32,
      "message": "Successfully obtained access token"
    },
    "paymentRecord": {
      "success": true,
      "totalPayments": 0
    }
  }
}
```

### Step 3: Set Up ngrok
```bash
ngrok http 5000
# Output: Forwarding  https://xxxx-xx-xxx-xx-x.ngrok.io -> http://localhost:5000
```

### Step 4: Update .env with ngrok URL
```env
BACKEND_BASE_URL=https://xxxx-xx-xxx-xx-x.ngrok.io
```

### Step 5: Restart Backend
```bash
# Stop current backend (Ctrl+C)
# Restart
node server.js
```

### Step 6: Test Payment from Flutter App
1. Start Flutter web app: `flutter run -d web`
2. Occupy a slot
3. Click "View Details"
4. Click "Pay" button
5. Check backend logs for payment flow

---

## Expected Backend Logs

### Successful Payment Request:
```
[MPESA] STK Push initiated: { phoneNumber: '+254712345678', amount: '1140.83', accountReference: '5' }
[MPESA] Formatted phone: 254712345678
[MPESA] Requesting token from Safaricom...
[MPESA] Token received successfully
[MPESA] Payload: { ... }
[MPESA] Sending request to: https://sandbox.safaricom.co.ke/mpesa/stkpush/v1/processrequest
[MPESA] Response: { ResponseCode: "0", ResponseDescription: "Accept the service request successfully." }
```

### On M-Pesa Payment (Sandbox):
```
[MPESA] Callback received: { Body: { stkCallback: { ... } } }
[MPESA] Result Code: 0
[MPESA] Payment successful: { receipt: 'ABC123', phone: '254712345678', amount: 1141 }
[MPESA] Payment record updated
```

---

## Frontend Error Handling

The Flutter app now provides detailed feedback:
- ✅ **Success**: "M-Pesa prompt sent successfully"
- ❌ **Callback URL Error**: Shows "Bad Request - Invalid CallBackURL" 
- ❌ **System Busy**: Shows "System is busy. Please try again..."
- ❌ **Network Error**: Shows "Network error: ..."

All errors display in red snackbars at the bottom of the screen.

---

## Environment Variables Checklist

Required `.env` variables:
- ✅ `MPESA_CONSUMER_KEY` - From Safaricom Developer Portal
- ✅ `MPESA_CONSUMER_SECRET` - From Safaricom Developer Portal  
- ✅ `MPESA_SHORTCODE` - 174379 (sandbox)
- ✅ `MPESA_PASSKEY` - From Safaricom Developer Portal (sandbox passkey)
- ✅ `BACKEND_BASE_URL` - Must be publicly accessible (use ngrok)
- ✅ `TWILIO_ACCOUNT_SID` - For SMS notifications
- ✅ `TWILIO_AUTH_TOKEN` - For SMS notifications
- ✅ `TWILIO_PHONE_NUMBER` - Your Twilio number

---

## Troubleshooting

| Error | Cause | Fix |
|-------|-------|-----|
| `Invalid CallBackURL` | Localhost not public | Use ngrok |
| `System is busy` | Safaricom sandbox overloaded | Retry after 1-2 minutes |
| `Invalid credentials` | Wrong consumer key/secret | Verify .env values |
| `Invalid phone number` | Format issue | Use format: `+254XXXXXXXXX` |
| `Invalid amount` | Amount < 1 KES | Ensure amount ≥ 1 |

---

## API Endpoints

### 1. Initiate Payment (STK Push)
**Endpoint**: `POST /api/mpesa/stkpush`
**Request**:
```json
{
  "phoneNumber": "+254712345678",
  "amount": "100",
  "accountReference": "5",
  "description": "Parking fee for slot 5"
}
```

**Response (Success)**:
```json
{
  "ok": true,
  "data": {
    "ResponseCode": "0",
    "ResponseDescription": "Accept the service request successfully."
  }
}
```

**Response (Error)**:
```json
{
  "ok": false,
  "error": "Bad Request - Invalid CallBackURL",
  "details": {
    "requestId": "817e-4506-982d-908095f0d03b14771",
    "errorCode": "400.002.02",
    "errorMessage": "Bad Request - Invalid CallBackURL"
  }
}
```

### 2. Payment Callback
**Endpoint**: `POST /api/mpesa/callback`
**Called by**: Safaricom (automatically)
**Updates**: Payment status in database

### 3. Diagnostic Test
**Endpoint**: `GET /api/mpesa/test`
**Purpose**: Verify payment setup
**Response**: Environment variables, token access, database connectivity

---

## Next Steps

1. **For local development**:
   - Install and run ngrok
   - Update `.env` with ngrok URL
   - Restart backend

2. **For production**:
   - Deploy backend to public server
   - Use production Safaricom credentials
   - Update BACKEND_BASE_URL to production domain

3. **Testing**:
   - Use real Safaricom test numbers
   - Monitor backend logs for payment flow
   - Verify SMS confirmations are sent
