<#
.SYNOPSIS
    Configuracao e provisionamento idempotente do LibreNMS
#>
if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot

Write-Host "Configurando LibreNMS..." -ForegroundColor Yellow

$port = 18080
$ps = docker compose ps --status running -q librenms 2>$null
if (-not [string]::IsNullOrWhiteSpace("$ps")) {
    $mapping = docker compose port librenms 8000 2>$null
    if ("$mapping" -match '127\.0\.0\.1:(\d+)') {
        $port = [int]$Matches[1]
    }
}
$url = "http://127.0.0.1:$port"

# 1. Remove flag de instalador web e limpa cache
docker compose exec -T librenms sh -c "sed -i '/^INSTALL=/d' /opt/librenms/.env /data/.env 2>/dev/null; rm -f /opt/librenms/bootstrap/cache/config.php; su -s /bin/bash librenms -c 'php /opt/librenms/artisan config:clear' 2>/dev/null" 2>$null

# 2. Configura base_url
Write-Host "Configurando base_url para $url..." -ForegroundColor Gray
docker compose exec -T librenms lnms config:set base_url "$url" 2>$null

# 3. Cria usuario admin com senha admin
Write-Host "Criando usuario admin..." -ForegroundColor Gray
docker compose exec -T librenms lnms user:add admin --password="GerenciaLab@2026!" --role=admin 2>$null
$adminBcrypt = '$2y$12$RYBNrtYUz66JRO1GkS4UQOWjSxtb.HhF1zVa1dkudGSJgqHFA8LuC'
"UPDATE users SET password = '$adminBcrypt' WHERE username = 'admin';" | docker compose exec -T db mariadb -u librenms -plab-db-local librenms 2>$null

# 4. Prime o scheduler cache
Write-Host "Inicializando agendador (Scheduler)..." -ForegroundColor Gray
docker compose exec -T --user librenms librenms php /opt/librenms/artisan schedule:run 2>$null

# Provisiona dashboard inicial
Get-Content "$PSScriptRoot\nms\setup-dashboard.php" | docker compose exec -T --user librenms librenms php 2>$null

# 5. Cadastra dispositivos
Write-Host "Cadastrando dispositivos gerenciados..." -ForegroundColor Gray
docker compose exec -T librenms lnms device:add firewall --v2c -c laboratorio 2>$null
docker compose exec -T librenms lnms device:add servidor1 --v2c -c laboratorio 2>$null
docker compose exec -T librenms lnms device:add servidor2 --v2c -c laboratorio 2>$null

# 6. Dispara descoberta
Write-Host "Disparando descoberta inicial..." -ForegroundColor Gray
docker compose exec -T -d --user librenms librenms php /opt/librenms/discovery.php -h all 2>$null

Write-Host "`nConfiguracao concluida com sucesso!" -ForegroundColor Green
Write-Host "Acesse: $url/login (admin / admin)" -ForegroundColor Cyan
