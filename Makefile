.PHONY: up down logs status certs clean agents restart backup lint

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

status:
	@echo "=== Docker Compose Status ==="
	docker compose ps
	@echo ""
	@echo "=== Registered Agents ==="
	docker exec -it wazuh.manager /var/ossec/bin/agent_control -lc 2>/dev/null || echo "Manager not ready"

certs:
	mkdir -p certs
	curl -sO https://packages.wazuh.com/4.8/wazuh-certs-tool.sh
	curl -sO https://packages.wazuh.com/4.8/config.yml
	@echo "[+] Edit config.yml, then run: bash wazuh-certs-tool.sh -A"
	@echo "[+] Then: mv ./wazuh-certificates/* ./certs/"

agents:
	@echo "Linux:   cd scripts && bash install-linux-agent.sh <MANAGER_IP>"
	@echo "Windows: cd scripts && powershell .\install-windows-agent.ps1"

clean:
	docker compose down -v
	docker system prune -f

restart:
	docker compose restart

backup:
	@echo "[+] Creating snapshot..."
	@echo "TODO: Configure OpenSearch snapshot repository (FS/S3)"
	@echo "See: https://documentation.wazuh.com/current/user-manual/manager/backup-restore.html"

lint:
	@echo "[+] Linting XML configs..."
	xmllint --noout config/wazuh_manager/*.xml agents/*.conf 2>/dev/null || echo "Install xmllint: apt install libxml2-utils"
	@echo "[+] Validating compose..."
	docker compose config > /dev/null && echo "OK" || echo "FAILED"
