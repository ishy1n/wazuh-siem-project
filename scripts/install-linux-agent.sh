#!/bin/bash
# Wazuh Linux Agent Installation Script

set -e

WAZUH_MANAGER="YOUR_MANAGER_IP"
WAZUH_VERSION="4.8.0"

echo "[*] Installing Wazuh Agent v${WAZUH_VERSION}..."

curl -s https://packages.wazuh.com/key/GPG-KEY-WAZUH | gpg --no-default-keyring --keyring gnupg-ring:/usr/share/keyrings/wazuh.gpg --import && chmod 644 /usr/share/keyrings/wazuh.gpg
echo "deb [signed-by=/usr/share/keyrings/wazuh.gpg] https://packages.wazuh.com/4.x/apt/ stable main" | tee /etc/apt/sources.list.d/wazuh.list

apt-get update
apt-get install -y wazuh-agent=${WAZUH_VERSION}-1

cp ./linux-ossec.conf /var/ossec/etc/ossec.conf
chown root:wazuh /var/ossec/etc/ossec.conf
chmod 640 /var/ossec/etc/ossec.conf

sed -i "s/wazuh.manager/${WAZUH_MANAGER}/g" /var/ossec/etc/ossec.conf

systemctl daemon-reload
systemctl enable wazuh-agent
systemctl start wazuh-agent

echo "[*] Wazuh Agent installed and started successfully!"
echo "[*] Check status: systemctl status wazuh-agent"
echo "[*] Check logs: tail -f /var/ossec/logs/ossec.log"
