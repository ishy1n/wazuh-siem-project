.PHONY: up down logs status certs clean agents restart backup

up:
	docker compose up -d

down:
	docker compose down

logs:
	docker compose logs -f

status:
	docker compose ps
	docker exec -it wazuh.manager /var/ossec/bin/agent_control -lc

certs:
	mkdir -p certs
	curl -sO https://packages.wazuh.com/4.8/wazuh-certs-tool.sh
	curl -sO https://packages.wazuh.com/4.8/config.yml
	@echo "Edit config.yml, then run: bash wazuh-certs-tool.sh -A"

agents:
	@echo "Install Linux agent: bash scripts/install-linux-agent.sh"
	@echo "Install Windows agent: powershell scripts/install-windows-agent.ps1"

clean:
	docker compose down -v
	docker system prune -f

restart:
	docker compose restart

backup:
	@echo "Creating backup..."
