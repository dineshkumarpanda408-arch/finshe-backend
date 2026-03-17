# Run this script as Administrator to allow the FinShe server to accept connections from your phone.
# Right-click PowerShell -> Run as Administrator, then: .\allow_server_firewall.ps1
# Use -UseBasicParsing to avoid the "Script Execution Risk" prompt.

$ruleName = "FinShe Node Server"
$existing = Get-NetFirewallRule -DisplayName $ruleName -ErrorAction SilentlyContinue
if ($existing) {
    Write-Host "Firewall rule '$ruleName' already exists."
} else {
    New-NetFirewallRule -DisplayName $ruleName -Direction Inbound -LocalPort 3000 -Protocol TCP -Action Allow
    Write-Host "Firewall rule added. Your phone can now connect to the server on port 3000."
}
