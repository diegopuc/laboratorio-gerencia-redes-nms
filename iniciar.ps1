$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot
function Test-Port([int]$Port) {
    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.ExclusiveAddressUse = $true
        $listener.Start()
        return $true
    } catch { return $false } finally { if ($listener) { $listener.Stop() } }
}
function Get-CurrentPort {
    $mapping = docker compose port librenms 8000 2>$null
    if ($LASTEXITCODE -eq 0 -and "$mapping" -match '127\.0\.0\.1:(\d+)$') { return [int]$Matches[1] }
    return 0
}
docker info *> $null
if ($LASTEXITCODE -ne 0) { Write-Host 'Inicie o Docker primeiro.'; exit 1 }
$current = Get-CurrentPort
if ($current) { Write-Host "LibreNMS ja publicado na porta $current. Pare o laboratorio para trocar a porta."; Start-Process "http://127.0.0.1:$current"; exit 0 }
$free = @(18080..18180 | Where-Object { Test-Port $_ } | Select-Object -First 10)
Write-Host "Portas livres sugeridas: $($free -join ', ')"
do {
    $raw = Read-Host 'Digite a porta desejada (1024-65535)'
    $port = 0
    $valid = [int]::TryParse($raw, [ref]$port) -and $port -ge 1024 -and $port -le 65535
    if ($valid) { $valid = Test-Port $port }
    if (-not $valid) { Write-Host 'Porta invalida ou ocupada. Escolha outra.' }
} until ($valid)
$envFile = Join-Path $PSScriptRoot '.env'
$lines = @(); if (Test-Path $envFile) { $lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^\s*(export\s+)?LIBRENMS_PORT\s*=' }) }
[IO.File]::WriteAllLines($envFile, [string[]]($lines + "LIBRENMS_PORT=$port"), [Text.UTF8Encoding]::new($false))
$env:LIBRENMS_PORT = "$port"
docker compose up -d --build
if ($LASTEXITCODE -ne 0) { Write-Host 'Falha ao iniciar. Execute novamente e escolha outra porta se houver conflito.'; exit 1 }
$actual = Get-CurrentPort
if ($actual -ne $port) { Write-Host 'Mapeamento inesperado. Nenhum navegador foi aberto.'; exit 1 }
$url = "http://127.0.0.1:$actual"
Write-Host "Aguardando LibreNMS em $url ..."
for ($i=0; $i -lt 60; $i++) {
    try { $r = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3; if ($r.StatusCode -lt 400) { Start-Process $url; Write-Host "Acesse $url. Se necessario, finalize o instalador e execute configurar.bat."; exit 0 } } catch {}
    Start-Sleep -Seconds 3
}
Write-Host "O servico ainda nao respondeu. Consulte docker compose logs librenms. Endereco: $url"
exit 1
