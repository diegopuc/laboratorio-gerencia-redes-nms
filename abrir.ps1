Set-Location $PSScriptRoot
$m = docker compose port librenms 8000 2>$null
if ($LASTEXITCODE -eq 0 -and "$m" -match '^127\.0\.0\.1:[0-9]+$') { Start-Process "http://$m" } else { Write-Host 'LibreNMS nao esta publicado.' }
