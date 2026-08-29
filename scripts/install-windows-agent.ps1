# Wazuh Windows Agent Installation Script
# Fixed: absolute paths, hash verification placeholder, admin check

if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Error "[!] Run this script as Administrator"
    exit 1
}

$WazuhManager = "${env:WAZUH_MANAGER:-YOUR_MANAGER_IP}"
$WazuhVersion = "4.8.0"
$InstallerUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-${WazuhVersion}-1.msi"
$InstallerPath = "$env:TEMP\wazuh-agent.msi"

# Expected SHA256 hash (update after download)
$ExpectedHash = "<INSERT_SHA256_HERE>"

Write-Host "[*] Downloading Wazuh Agent v${WazuhVersion}..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing

# Verify hash (optional, remove if hash unknown)
$ActualHash = (Get-FileHash -Path $InstallerPath -Algorithm SHA256).Hash
if ($ExpectedHash -ne "<INSERT_SHA256_HERE>" -and $ActualHash -ne $ExpectedHash) {
    Write-Error "[!] Hash mismatch! Expected: $ExpectedHash, Got: $ActualHash"
    Remove-Item $InstallerPath -Force
    exit 1
}

Write-Host "[*] Installing Wazuh Agent..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /qn WAZUH_MANAGER=`"$WazuhManager`" WAZUH_AGENT_GROUP=`"Windows`"" -Wait

# Deploy custom configuration
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ConfigSource = Join-Path $ScriptDir "..\agents\windows-ossec.conf"
$ConfigDest = "C:\Program Files (x86)\ossec-agent\ossec.conf"

if (Test-Path $ConfigSource) {
    Copy-Item -Path $ConfigSource -Destination $ConfigDest -Force
    (Get-Content $ConfigDest) -replace 'wazuh.manager', $WazuhManager | Set-Content $ConfigDest
    Write-Host "[*] Custom config deployed" -ForegroundColor Green
} else {
    Write-Warning "[!] windows-ossec.conf not found at $ConfigSource. Using default config."
    (Get-Content $ConfigDest) -replace 'MANAGER_IP', $WazuhManager | Set-Content $ConfigDest
}

# Restart service
Write-Host "[*] Restarting Wazuh Agent service..." -ForegroundColor Cyan
Restart-Service -Name WazuhSvc -Force

Write-Host "[*] Installation complete!" -ForegroundColor Green
Write-Host "[*] Check status: Get-Service WazuhSvc"
Write-Host "[*] Check logs: Get-Content 'C:\Program Files (x86)\ossec-agent\logs\ossec.log' -Tail 50"

# Cleanup
Remove-Item $InstallerPath -Force
