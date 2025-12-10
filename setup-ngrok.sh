#!/bin/bash
# Alternative setup for Linux/Mac users (for reference)

echo "=== Smart Parking System - ngrok Setup (Linux/Mac) ==="

# Check if ngrok is installed
if ! command -v ngrok &> /dev/null; then
    echo "❌ ngrok not found. Please install it first:"
    echo "   https://ngrok.com/download"
    exit 1
fi

echo "✅ ngrok found"

# Get auth token from .env
AUTHTOKEN=$(grep NGROK_AUTHTOKEN backend/.env | cut -d '=' -f 2 | tr -d ' ')

if [ -z "$AUTHTOKEN" ]; then
    echo "❌ NGROK_AUTHTOKEN not found in backend/.env"
    exit 1
fi

echo "✅ Auth token found: ${AUTHTOKEN:0:10}..."

# Kill existing ngrok
pkill -f ngrok

echo ""
echo "🚀 Starting ngrok tunnel on port 5000..."
echo ""

# Start ngrok
ngrok http 5000 --authtoken=$AUTHTOKEN &
NGROK_PID=$!

# Wait for ngrok to start
sleep 3

# Get public URL
PUBLIC_URL=$(curl -s http://localhost:4040/api/tunnels | grep -o '"public_url":"[^"]*"' | head -1 | cut -d '"' -f 4)

if [ -z "$PUBLIC_URL" ]; then
    echo "❌ Could not get public URL from ngrok"
    echo "   Try manually visiting: http://localhost:4040"
    exit 1
fi

echo "✅ ngrok tunnel established!"
echo ""
echo "📍 Public URL: $PUBLIC_URL"
echo ""

# Update .env
sed -i.bak "s|BACKEND_BASE_URL=.*|BACKEND_BASE_URL=$PUBLIC_URL|" backend/.env

echo "📝 Updated .env with ngrok URL"
echo ""

# Display instructions
echo "========================================"
echo ""
echo "✅ ngrok Setup Complete!"
echo ""
echo "Next steps:"
echo "  1. In another terminal, start the backend:"
echo "     cd backend && node server.js"
echo ""
echo "  2. In another terminal, start the Flutter app:"
echo "     cd flutter_app && flutter run -d chrome"
echo ""
echo "  3. Test payment flow in the app"
echo ""
echo "🔗 ngrok dashboard: http://localhost:4040"
echo ""
echo "⚠️  Keep this terminal open - ngrok needs to stay running!"
echo ""

wait $NGROK_PID
