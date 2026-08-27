# Руководство по развёртыванию Wazuh SIEM

## Содержание
1. [Требования](#требования)
2. [Подготовка сервера](#подготовка-сервера)
3. [Генерация TLS-сертификатов](#генерация-tls-сертификатов)
4. [Запуск кластера](#запуск-кластера)
5. [Установка агентов](#установка-агентов)
6. [Проверка работоспособности](#проверка-работоспособности)
7. [Устранение неполадок](#устранение-неполадок)

---

## Требования

### Аппаратные

| Компонент | Минимум | Рекомендуется |
|---|---|---|
| CPU | 2 ядра | 4 ядра |
| RAM | 4 GB | 8 GB |
| Диск | 20 GB SSD | 50 GB SSD |
| Сеть | 1 Gbps | 1 Gbps |

### Программные

- Ubuntu 22.04/24.04 LTS
- Docker 24.0+
- Docker Compose 2.20+
- curl, jq

---

## Подготовка сервера

```bash
# Обновление системы
sudo apt update && sudo apt upgrade -y

# Установка Docker
sudo apt install -y docker.io docker-compose-plugin jq curl

# Добавление пользователя в группу docker
sudo usermod -aG docker $USER
newgrp docker

# Проверка
docker --version
docker compose version
```

---

## Генерация TLS-сертификатов

Wazuh требует TLS-сертификаты для всех компонентов.

```bash
# Создаём директорию
mkdir -p certs

# Скачиваем инструменты
curl -sO https://packages.wazuh.com/4.8/wazuh-certs-tool.sh
curl -sO https://packages.wazuh.com/4.8/config.yml
```

Отредактируйте `config.yml`:

```yaml
nodes:
  indexer:
    - name: wazuh.indexer
      ip: "127.0.0.1"
  server:
    - name: wazuh.manager
      ip: "127.0.0.1"
  dashboard:
    - name: wazuh.dashboard
      ip: "127.0.0.1"
```

```bash
# Генерация
bash wazuh-certs-tool.sh -A

# Перемещение
mv ./wazuh-certificates/* ./certs/
rm -rf ./wazuh-certificates
```

---

## Запуск кластера

```bash
# Клонирование репозитория
git clone https://github.com/YOUR_USERNAME/wazuh-siem-project.git
cd wazuh-siem-project

# Настройка окружения
cp .env.example .env
# Отредактируйте .env

# Запуск
docker compose up -d

# Проверка статуса
docker compose ps

# Логи менеджера
docker logs -f wazuh.manager
```

### Порты

| Порт | Сервис | Описание |
|---|---|---|
| 9200 | wazuh.indexer | OpenSearch API |
| 1514/udp | wazuh.manager | Агенты (syslog) |
| 1515 | wazuh.manager | Регистрация агентов |
| 55000 | wazuh.manager | Wazuh API |
| 5601 | wazuh.dashboard | Веб-интерфейс |

---

## Установка агентов

### Linux

```bash
# На целевом хосте
cd scripts
export WAZUH_MANAGER="YOUR_SERVER_IP"
sed -i "s/YOUR_MANAGER_IP/$WAZUH_MANAGER/g" install-linux-agent.sh
bash install-linux-agent.sh
```

### Windows

```powershell
# PowerShell от имени Администратора
cd scripts
$WazuhManager = "YOUR_SERVER_IP"
(Get-Content install-windows-agent.ps1) -replace 'YOUR_MANAGER_IP', $WazuhManager | Set-Content install-windows-agent.ps1
.\install-windows-agent.ps1
```

---

## Проверка работоспособности

### 1. Dashboard

Откройте `https://YOUR_SERVER_IP:5601`

### 2. API

```bash
curl -k -u admin:SecretPassword https://localhost:55000/agents?pretty=true
```

### 3. Агенты

```bash
docker exec -it wazuh.manager /var/ossec/bin/agent_control -lc
```

### 4. Алерты

```bash
docker exec -it wazuh.manager tail -f /var/ossec/logs/alerts/alerts.json | jq
```

---

## Устранение неполадок

### Проблема: Агент не подключается

**Решение:**
```bash
# Проверка порта
nc -zv YOUR_MANAGER_IP 1514

# Перерегистрация
/var/ossec/bin/agent-auth -m YOUR_MANAGER_IP -A $(hostname)
systemctl restart wazuh-agent
```

### Проблема: Dashboard недоступен

**Решение:**
```bash
# Проверка сертификатов
docker logs wazuh.dashboard | grep -i error

# Перезапуск
docker compose restart wazuh.dashboard
```

### Проблема: Нет алертов

**Решение:**
```bash
# Проверка правил
docker exec -it wazuh.manager /var/ossec/bin/wazuh-logtest

# Проверка логов
docker logs wazuh.manager | grep -i error
```
