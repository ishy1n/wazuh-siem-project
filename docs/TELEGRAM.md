# Настройка Telegram-оповещений

## Создание бота

1. Откройте [@BotFather](https://t.me/BotFather)
2. Отправьте `/newbot`
3. Следуйте инструкциям, получите **BOT_TOKEN**

## Получение CHAT_ID

### Личные сообщения

1. Откройте [@userinfobot](https://t.me/userinfobot)
2. Отправьте любое сообщение боту
3. Получите ваш ID

### Групповой чат

1. Добавьте бота в группу
2. Отправьте сообщение в группу
3. Выполните:
   ```bash
   curl https://api.telegram.org/bot<BOT_TOKEN>/getUpdates
   ```
4. Найдите `"chat":{"id":-100...` — это ваш CHAT_ID

## Настройка Wazuh

1. Отредактируйте `scripts/custom-telegram.sh`:
   ```bash
   BOT_TOKEN="123456789:ABCdefGHIjklMNOpqrsTUVwxyz"
   CHAT_ID="-1001234567890"
   ```

2. Убедитесь, что скрипт доступен в контейнере:
   ```bash
   docker compose restart wazuh.manager
   ```

3. Проверьте права:
   ```bash
   docker exec -it wazuh.manager ls -la /var/ossec/integrations/custom-telegram
   ```

## Тестирование

```bash
# Симуляция брутфорса
for i in {1..10}; do ssh wronguser@target-ip; done
```

Ожидайте сообщение в Telegram в течение 2-3 минут.

## Формат сообщения

```
🚨 WAZUH SECURITY ALERT 🚨

Severity: CRITICAL (Level 12)
Rule ID: 100002
Description: Possible Successful SSH Brute Force...
Agent: linux-web-01 (192.168.1.10)
Time: 2026-08-25T08:19:00+03:00
Source IP: 10.0.0.50
Target User: root

Full Log:
```
Aug 25 08:19:00 sshd[1234]: Accepted password for root from 10.0.0.50 port 54321
```

Project 1 — Wazuh SIEM Correlation
```

## Устранение неполадок

### Сообщения не приходят

1. Проверьте токен и CHAT_ID
2. Убедитесь, что jq установлен в контейнере
3. Проверьте логи:
   ```bash
   docker exec -it wazuh.manager tail -f /var/ossec/logs/integrations.log
   ```

### Ошибка 404

- Бот не инициализирован — отправьте `/start` боту

### Ошибка 403

- Бот заблокирован — разблокируйте в настройках Telegram
