#!/bin/bash
# Wazuh Custom Integration — Telegram Alerts

BOT_TOKEN="YOUR_BOT_TOKEN_HERE"
CHAT_ID="YOUR_CHAT_ID_HERE"
API_URL="https://api.telegram.org/bot${BOT_TOKEN}/sendMessage"

ALERT=$(cat)

ALERT_LEVEL=$(echo "$ALERT" | jq -r '.rule.level // "N/A"')
ALERT_DESCRIPTION=$(echo "$ALERT" | jq -r '.rule.description // "No description"')
ALERT_ID=$(echo "$ALERT" | jq -r '.rule.id // "N/A"')
AGENT_NAME=$(echo "$ALERT" | jq -r '.agent.name // "N/A"')
AGENT_IP=$(echo "$ALERT" | jq -r '.agent.ip // "N/A"')
TIMESTAMP=$(echo "$ALERT" | jq -r '.timestamp // "N/A"')
SRC_IP=$(echo "$ALERT" | jq -r '(.data.srcip // .data.win.system.ipAddress // "N/A")')
DST_USER=$(echo "$ALERT" | jq -r '(.data.dstuser // .data.win.eventdata.targetUserName // "N/A")')
FULL_LOG=$(echo "$ALERT" | jq -r '.full_log // "N/A"')

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

MESSAGE="${EMOJI} *WAZUH SECURITY ALERT* ${EMOJI}

*Severity:* ${SEVERITY} (Level ${ALERT_LEVEL})
*Rule ID:* ${ALERT_ID}
*Description:* ${ALERT_DESCRIPTION}
*Agent:* ${AGENT_NAME} (${AGENT_IP})
*Time:* ${TIMESTAMP}
*Source IP:* ${SRC_IP}
*Target User:* ${DST_USER}

*Full Log:*
\`\`\`
${FULL_LOG}
\`\`\`

_Project 1 — Wazuh SIEM Correlation_"

curl -s -X POST "$API_URL" \
    -H "Content-Type: application/json" \
    -d "{
        \"chat_id\": \"${CHAT_ID}\",
        \"text\": \"${MESSAGE}\",
        \"parse_mode\": \"MarkdownV2\",
        \"disable_web_page_preview\": true
    }" > /dev/null 2>&1

echo "$(date '+%Y-%m-%d %H:%M:%S') — Telegram alert sent for Rule ${ALERT_ID}, Level ${ALERT_LEVEL}" >> /var/ossec/logs/integrations.log

exit 0
