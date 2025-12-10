Write-Host "=== Smart Parking System - ngrok Setup ===" -ForegroundColor Cyan
Write-Host ""

# Check if ngrok is installed
$ngrokPath = Get-Command ngrok -ErrorAction SilentlyContinue
if (-not $ngrokPath) {
    Write-Host "ERROR: ngrok not found. Please install it first:" -ForegroundColor Red
    Write-Host "  https://ngrok.com/download" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: ngrok found" -ForegroundColor Green

# Check if auth token is set in .env
$envPath = "backend\.env"
if (-not (Test-Path $envPath)) {
    Write-Host "ERROR: .env file not found at $envPath" -ForegroundColor Red
    exit 1
}

$envContent = Get-Content $envPath -Raw
$authToken = $null
if ($envContent -match 'NGROK_AUTHTOKEN=(.+?)(?:\r?\n|$)') {
    $authToken = $matches[1].Trim()
}

if (-not $authToken) {
    Write-Host "ERROR: NGROK_AUTHTOKEN not found in .env" -ForegroundColor Red
    exit 1
}

Write-Host "OK: Auth token found: $($authToken.Substring(0, 10))..." -ForegroundColor Green
Write-Host ""

# Kill any existing ngrok processes
Write-Host "Stopping existing ngrok processes..." -ForegroundColor Yellow
Get-Process ngrok -ErrorAction SilentlyContinue | Stop-Process -Force -ErrorAction SilentlyContinue

# Start ngrok
Write-Host "Starting ngrok tunnel on port 5000..." -ForegroundColor Cyan
$ngrokProcess = Start-Process ngrok -ArgumentList "http", "5000", "--authtoken=$authToken" -NoNewWindow -PassThru

# Wait for ngrok to start
Start-Sleep -Seconds 3

# Try to get the public URL from ngrok API
$maxRetries = 5
$retry = 0
$publicUrl = $null

while ($retry -lt $maxRetries) {
    if ($publicUrl) {
        break
    }
    
    try {
        $response = Invoke-RestMethod -Uri "http://localhost:4040/api/tunnels" -ErrorAction Stop
        $publicUrl = $response.tunnels[0].public_url
    }
    catch {
        $retry++
        if ($retry -lt $maxRetries) {
            Start-Sleep -Seconds 1
        }
    }
}

if (-not $publicUrl) {
    Write-Host "ERROR: Could not get public URL from ngrok" -ForegroundColor Red
    Write-Host "Try visiting: http://localhost:4040" -ForegroundColor Yellow
    exit 1
}

Write-Host "OK: ngrok tunnel established!" -ForegroundColor Green
Write-Host ""
Write-Host "Public URL: $publicUrl" -ForegroundColor Yellow
Write-Host ""

# Update .env with the new public URL
Write-Host "Updating .env with ngrok URL..." -ForegroundColor Cyan
$envContent = $envContent -replace 'BACKEND_BASE_URL=.*', "BACKEND_BASE_URL=$publicUrl"
Set-Content -Path $envPath -Value $envContent -Encoding UTF8

Write-Host "OK: .env updated" -ForegroundColor Green
Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "SUCCESS: ngrok Setup Complete!" -ForegroundColor Green
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Cyan
Write-Host "  1. Open NEW terminal and start backend:" -ForegroundColor Yellow
Write-Host "     cd backend && node server.js" -ForegroundColor White
Write-Host ""
Write-Host "  2. Open another NEW terminal and start Flutter:" -ForegroundColor Yellow
Write-Host "     cd flutter_app && flutter run -d chrome" -ForegroundColor White
Write-Host ""
Write-Host "  3. Test payment in the app" -ForegroundColor Yellow
Write-Host ""
Write-Host "Dashboard: http://localhost:4040" -ForegroundColor Cyan
Write-Host ""
Write-Host "NOTE: Keep this terminal open - ngrok must stay running!" -ForegroundColor Yellow
Write-Host ""

# Keep the script running
Write-Host "Press Ctrl+C to stop ngrok..." -ForegroundColor Gray
$ngrokProcess.WaitForExit()
