#!/bin/bash
# Wazuh Custom Integration — Telegram Alerts
# Fixed: Markdown escaping, retry logic, input validation, error handling

set -euo pipefail

BOT_TOKEN="${TELEGRAM_BOT_TOKEN:-YOUR_BOT_TOKEN_HERE}"
CHAT_ID="${TELEGRAM_CHAT_ID:-YOUR_CHAT_ID_HERE}"
API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

# Read alert data from stdin (Wazuh passes JSON)
ALERT=$(cat)

# Extract fields using jq
ALERT_LEVEL=$(echo "$ALERT" | jq -r '.rule.level // "0"')
ALERT_DESCRIPTION=$(echo "$ALERT" | jq -r '.rule.description // "No description"')
ALERT_ID=$(echo "$ALERT" | jq -r '.rule.id // "N/A"')
AGENT_NAME=$(echo "$ALERT" | jq -r '.agent.name // "N/A"')
AGENT_IP=$(echo "$ALERT" | jq -r '.agent.ip // "N/A"')
TIMESTAMP=$(echo "$ALERT" | jq -r '.timestamp // "N/A"')
SRC_IP=$(echo "$ALERT" | jq -r '(.data.srcip // .data.win.system.ipAddress // "N/A")')
DST_USER=$(echo "$ALERT" | jq -r '(.data.dstuser // .data.win.eventdata.targetUserName // "N/A")')
FULL_LOG=$(echo "$ALERT" | jq -r '.full_log // "N/A"')

# Validate ALERT_LEVEL is a number
if ! [[ "$ALERT_LEVEL" =~ ^[0-9]+$ ]]; then
    ALERT_LEVEL=0
fi

# Escape special characters for Telegram MarkdownV2
escape_md() {
    echo "$1" | sed 's/[_*\[\]()~`>#+=|{}.!-]/\\&/g'
}

# Determine severity emoji
if [ "$ALERT_LEVEL" -ge 12 ]; then
    EMOJI="🚨"
    SEVERITY="CRITICAL"
elif [ "$ALERT_LEVEL" -ge 8 ]; then
    EMOJI="⚠️"
    SEVERITY="HIGH"
elif [ "$ALERT_LEVEL" -ge 6 ]; then
    EMOJI="🔶"
    SEVERITY="MEDIUM"
else
    EMOJI="ℹ️"
    SEVERITY="LOW"
fi

# Build message with escaped fields
SAFE_DESC=$(escape_md "$ALERT_DESCRIPTION")
SAFE_AGENT=$(escape_md "$AGENT_NAME")
SAFE_IP=$(escape_md "$AGENT_IP")
SAFE_TIME=$(escape_md "$TIMESTAMP")
SAFE_SRC=$(escape_md "$SRC_IP")
SAFE_DST=$(escape_md "$DST_USER")
SAFE_LOG=$(escape_md "$FULL_LOG")

MESSAGE="${EMOJI} *WAZUH SECURITY ALERT* ${EMOJI}

*Severity:* $(escape_md "$SEVERITY") (Level ${ALERT_LEVEL})
*Rule ID:* ${ALERT_ID}
*Description:* ${SAFE_DESC}
*Agent:* ${SAFE_AGENT} (${SAFE_IP})
*Time:* ${SAFE_TIME}
*Source IP:* ${SAFE_SRC}
*Target User:* ${SAFE_DST}

*Full Log:*
\`\`\`
${SAFE_LOG}
\`\`\`

_Project 1 — Wazuh SIEM Correlation_"

# Send to Telegram with retry logic
SUCCESS=0
for i in 1 2 3; do
    if curl -fsS -m 10 -X POST "$API_URL" \
        -H "Content-Type: application/json" \
        -d "{
            \"chat_id\": \"${CHAT_ID}\",
            \"text\": \"${MESSAGE}\",
            \"parse_mode\": \"MarkdownV2\",
            \"disable_web_page_preview\": true
        }" > /dev/null 2>&1; then
        SUCCESS=1
        break
    fi
    sleep 2
done

# Log execution
if [ "$SUCCESS" -eq 1 ]; then
    echo "$(date '+%Y-%m-%d %H:%M:%S') — Telegram alert sent for Rule ${ALERT_ID}, Level ${ALERT_LEVEL}" >> /var/ossec/logs/integrations.log
    exit 0
else
    echo "$(date '+%Y-%m-%d %H:%M:%S') — ERROR: Failed to send Telegram alert for Rule ${ALERT_ID}" >> /var/ossec/logs/integrations.log
    exit 1
fi
