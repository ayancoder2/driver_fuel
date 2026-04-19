# FuelDirect - Supabase Edge Function Deployment Script
# 
# PREREQUISITES:
#   1. Get your Supabase Personal Access Token from:
#      https://supabase.com/dashboard/account/tokens
#   2. Run this script in PowerShell:
#      .\deploy_edge_function.ps1 -Token "sbp_xxxxxxxxxxxxx"

param(
    [Parameter(Mandatory=$true)]
    [string]$Token
)

$supabase = "$env:USERPROFILE\AppData\Local\supabase\supabase.exe"
$projectRef = "fsxiioldnxdzidcunmma"
$projectRoot = $PSScriptRoot

Write-Host "====================================" -ForegroundColor Cyan
Write-Host " FuelDirect Notification Deployment" -ForegroundColor Cyan  
Write-Host "====================================" -ForegroundColor Cyan
Write-Host ""

# Step 1: Login with token
Write-Host "[1/4] Authenticating with Supabase..." -ForegroundColor Yellow
& $supabase login --token $Token
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Login failed. Please check your token." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Authenticated!" -ForegroundColor Green

# Step 2: Link project
Write-Host ""
Write-Host "[2/4] Linking to project $projectRef..." -ForegroundColor Yellow
& $supabase link --project-ref $projectRef --workdir $projectRoot
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Project link failed." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Project linked!" -ForegroundColor Green

# Step 3: Deploy the Edge Function
Write-Host ""
Write-Host "[3/4] Deploying send-notification Edge Function..." -ForegroundColor Yellow
& $supabase functions deploy send-notification --workdir $projectRoot --no-verify-jwt
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERROR] Deployment failed." -ForegroundColor Red
    exit 1
}
Write-Host "[OK] Edge Function deployed!" -ForegroundColor Green

# Step 4: Run the database migration (using the Management API)
Write-Host ""
Write-Host "[4/4] Running database migration (adding fcm_token columns)..." -ForegroundColor Yellow

$sql = @"
ALTER TABLE drivers ADD COLUMN IF NOT EXISTS fcm_token TEXT;
ALTER TABLE profiles ADD COLUMN IF NOT EXISTS fcm_token TEXT;
CREATE INDEX IF NOT EXISTS idx_drivers_fcm_token ON drivers(fcm_token) WHERE fcm_token IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_profiles_fcm_token ON profiles(fcm_token) WHERE fcm_token IS NOT NULL;
"@

$headers = @{
    "Authorization" = "Bearer $Token"
    "Content-Type" = "application/json"
}

$body = @{ query = $sql } | ConvertTo-Json

try {
    $response = Invoke-RestMethod `
        -Uri "https://api.supabase.com/v1/projects/$projectRef/database/query" `
        -Method POST `
        -Headers $headers `
        -Body $body
    Write-Host "[OK] Migration executed!" -ForegroundColor Green
} catch {
    Write-Host "[WARNING] Migration API call failed - please run manually in Supabase SQL Editor:" -ForegroundColor Yellow
    Write-Host $sql -ForegroundColor Gray
}

Write-Host ""
Write-Host "====================================" -ForegroundColor Green
Write-Host " Deployment Complete!" -ForegroundColor Green
Write-Host "====================================" -ForegroundColor Green
Write-Host ""
Write-Host "Edge Function URL:" -ForegroundColor Cyan
Write-Host "  https://$projectRef.supabase.co/functions/v1/send-notification" -ForegroundColor White
Write-Host ""
Write-Host "Next: Test by running the app and accepting an order." -ForegroundColor Cyan
