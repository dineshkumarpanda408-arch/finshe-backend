# FinShe Chat API Test Script - Shows FULL response (no truncation)
# Usage: .\test-chat.ps1
# Usage: .\test-chat.ps1 "Your question here"
# Usage: .\test-chat.ps1 -Message "Your question" -Server "http://localhost:3000"

param(
    [string]$Message = "Can you suggest some colleges for masters study abroad?",
    [string]$Server = "http://localhost:3000"
)

$body = @{ message = $Message; context = @{} } | ConvertTo-Json -Depth 3
$uri = "$Server/api/chat"

Write-Host "Sending to $uri ..." -ForegroundColor Cyan
Write-Host ""

try {
    $response = Invoke-RestMethod -Uri $uri -Method POST -Body $body -ContentType "application/json; charset=utf-8" -UseBasicParsing
    
    if ($response.reply) {
        Write-Host "=== FULL REPLY ===" -ForegroundColor Green
        Write-Host $response.reply
        Write-Host ""
        Write-Host "=== END (length: $($response.reply.Length) chars) ===" -ForegroundColor Green
    } else {
        Write-Host "Response:" ($response | ConvertTo-Json -Depth 5)
    }
} catch {
    if ($_.Exception.Response) {
        $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
        $reader.BaseStream.Position = 0
        $reader.DiscardBufferedData()
        $errBody = $reader.ReadToEnd()
        Write-Host "Error: $errBody" -ForegroundColor Red
    } else {
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
