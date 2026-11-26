@echo off
cd /d "%~dp0"
docker compose exec -T librenms lnms user:add admin --password=gerencia123 --role=admin
for %%H in (servidor1 servidor2 firewall) do docker compose exec -T librenms lnms device:add %%H --v2c -c laboratorio
pause
