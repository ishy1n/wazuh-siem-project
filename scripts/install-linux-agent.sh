#!/bin/bash
# Wazuh Linux Agent Installation Script
# Fixed: error handling, root check, trap

set -euo pipefail

trap 'echo "[ERROR] Installation failed at line $LINENO" >&2; exit 1' ERR

if [ "$EUID" -ne 0 ]; then
    echo "[!] Run this script as root"
    exit 1
fi

WAZUH_MANAGER="${1:-YOUR_MANAGER_IP}"
WAZUH_VERSION="4.8.0"

echo "[*] Installing Wazuh Agent v${WAZUH_VERSION}..."

# Add Wazuh repository
curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

apt-get update
apt-get install -y wazuh-agent=${WAZUH_VERSION}-1

# Deploy custom configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cp "${SCRIPT_DIR}/../agents/linux-ossec.conf" /var/ossec/etc/ossec.conf
chown root:wazuh /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

# Set manager address
sed -i "s/wazuh.manager/${WAZUH_MANAGER}/g" /var/ossec/etc/ossec.conf

# Enable and start service
systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "[*] Wazuh Agent installed and started successfully!"
echo "[*] Check status: systemctl status wazuh-agent"
echo "[*] Check logs: tail -f /var/ossec/logs/ossec.log"
