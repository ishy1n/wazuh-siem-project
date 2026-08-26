# Wazuh Windows Agent Installation Script
# Run as Administrator in PowerShell

$WazuhManager = "YOUR_MANAGER_IP"
$WazuhVersion = "4.8.0"
$InstallerUrl = "https://packages.wazuh.com/4.x/windows/wazuh-agent-${WazuhVersion}-1.msi"
$InstallerPath = "$env:TEMP\wazuh-agent.msi"

Write-Host "[*] Downloading Wazuh Agent v${WazuhVersion}..." -ForegroundColor Cyan
Invoke-WebRequest -Uri $InstallerUrl -OutFile $InstallerPath -UseBasicParsing

Write-Host "[*] Installing Wazuh Agent..." -ForegroundColor Cyan
Start-Process msiexec.exe -ArgumentList "/i `"$InstallerPath`" /qn WAZUH_MANAGER=`"$WazuhManager`" WAZUH_AGENT_GROUP=`"Windows`"" -Wait

Write-Host "[*] Deploying custom ossec.conf..." -ForegroundColor Cyan
$ConfigSource = ".\windows-ossec.conf"
$ConfigDest = "C:\Program Files (x86)\ossec-agent\ossec.conf"
Copy-Item -Path $ConfigSource -Destination $ConfigDest -Force

(Get-Content $ConfigDest) -replace 'wazuh.manager', $WazuhManager | Set-Content $ConfigDest

Write-Host "[*] Restarting Wazuh Agent service..." -ForegroundColor Cyan
Restart-Service -Name WazuhSvc -Force

Write-Host "[*] Installation complete!" -ForegroundColor Green
Write-Host "[*] Check status: Get-Service WazuhSvc"
Write-Host "[*] Check logs: Get-Content 'C:\Program Files (x86)\ossec-agent\logs\ossec.log' -Tail 50"

Remove-Item $InstallerPath -Force
