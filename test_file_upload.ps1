# Test file upload ke endpoint parent/apply-leaves
# Jalankan: .\test_file_upload.ps1

# === KONFIGURASI ===
# Ganti token ini dengan token parent yang aktif (ambil dari log flutter)
$TOKEN = "118|n1pBC71dMaMo0ONy8QiUuUtWr1P9ywEjhEpoESb703505a" # GANTI dengan token lengkap dari log flutter
$SCHOOL_CODE = "SCH20260044"
$BASE_URL = "https://devapisekolah.eschool.ac.id/api"
$CHILD_ID = "1413"

# Buat file test gambar kecil (1x1 pixel PNG)
$testImagePath = "$PSScriptRoot\test_upload_image.png"
# Membuat PNG 1x1 pixel minimal
$pngBytes = [byte[]]@(
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,  # PNG signature
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,  # IHDR chunk
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,  # 1x1
    0x08, 0x02, 0x00, 0x00, 0x00, 0x90, 0x77, 0x53,
    0xDE, 0x00, 0x00, 0x00, 0x0C, 0x49, 0x44, 0x41,  # IDAT chunk
    0x54, 0x08, 0xD7, 0x63, 0xF8, 0xCF, 0xC0, 0x00,
    0x00, 0x00, 0x02, 0x00, 0x01, 0xE2, 0x21, 0xBC,
    0x33, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E,  # IEND chunk
    0x44, 0xAE, 0x42, 0x60, 0x82
)
[System.IO.File]::WriteAllBytes($testImagePath, $pngBytes)
Write-Host "Test image created: $testImagePath" -ForegroundColor Cyan

# === TEST 1: Upload dengan files[0] ===
Write-Host "`n=== TEST 1: Upload dengan key 'files[0]' ===" -ForegroundColor Yellow
try {
    $form = @{
        "child_id" = $CHILD_ID
        "reason" = "Test upload file dari PowerShell - files[0]"
        "leave_details[0][date]" = "2026-07-16"
        "leave_details[0][type]" = "Sick"
        "files[0]" = Get-Item $testImagePath
    }
    $headers = @{
        "Authorization" = "Bearer $TOKEN"
        "Accept" = "application/json"
        "school-code" = $SCHOOL_CODE
    }
    $r = Invoke-WebRequest -Uri "$BASE_URL/parent/apply-leaves" -Method Post -Headers $headers -Form $form -ErrorAction Stop
    Write-Host "STATUS: $($r.StatusCode)" -ForegroundColor Green
    Write-Host "RESPONSE: $($r.Content)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    try {
        $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $sr.ReadToEnd(); $sr.Close()
    } catch { $body = $_.Exception.Message }
    Write-Host "FAIL ($code): $body" -ForegroundColor Red
}

# === TEST 2: Upload dengan files[] ===
Write-Host "`n=== TEST 2: Upload dengan key 'files[]' ===" -ForegroundColor Yellow
try {
    $form2 = @{
        "child_id" = $CHILD_ID
        "reason" = "Test upload file dari PowerShell - files[]"
        "leave_details[0][date]" = "2026-07-16"
        "leave_details[0][type]" = "Sick"
        "files[]" = Get-Item $testImagePath
    }
    $r2 = Invoke-WebRequest -Uri "$BASE_URL/parent/apply-leaves" -Method Post -Headers $headers -Form $form2 -ErrorAction Stop
    Write-Host "STATUS: $($r2.StatusCode)" -ForegroundColor Green
    Write-Host "RESPONSE: $($r2.Content)" -ForegroundColor Green
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    try {
        $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $sr.ReadToEnd(); $sr.Close()
    } catch { $body = $_.Exception.Message }
    Write-Host "FAIL ($code): $body" -ForegroundColor Red
}

# === TEST 3: Cek data leaves untuk melihat apakah file tersimpan ===
Write-Host "`n=== TEST 3: Ambil data leaves untuk cek file ===" -ForegroundColor Yellow
try {
    $r3 = Invoke-WebRequest -Uri "$BASE_URL/parent/child-leaves?child_id=$CHILD_ID" -Method Get -Headers $headers -ErrorAction Stop
    $jsonData = $r3.Content | ConvertFrom-Json
    Write-Host "STATUS: $($r3.StatusCode)" -ForegroundColor Green
    
    # Tampilkan data leave terbaru
    if ($jsonData.data -and $jsonData.data.Count -gt 0) {
        $latest = $jsonData.data[0]
        Write-Host "`nLeave terbaru:" -ForegroundColor Cyan
        Write-Host "  ID: $($latest.id)"
        Write-Host "  Reason: $($latest.reason)"
        Write-Host "  Status: $($latest.status)"
        Write-Host "  File: $($latest.file | ConvertTo-Json -Depth 5)" -ForegroundColor Magenta
        Write-Host "  Files: $($latest.files | ConvertTo-Json -Depth 5)" -ForegroundColor Magenta
        Write-Host "`nFull JSON (leave pertama):" -ForegroundColor Cyan
        Write-Host ($latest | ConvertTo-Json -Depth 5)
    } else {
        Write-Host "Tidak ada data leaves" -ForegroundColor Red
    }
} catch {
    $code = $_.Exception.Response.StatusCode.value__
    try {
        $sr = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $body = $sr.ReadToEnd(); $sr.Close()
    } catch { $body = $_.Exception.Message }
    Write-Host "FAIL ($code): $body" -ForegroundColor Red
}

# Cleanup
Remove-Item $testImagePath -ErrorAction SilentlyContinue
Write-Host "`nDone!" -ForegroundColor Cyan
