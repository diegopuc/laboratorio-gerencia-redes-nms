<#
.SYNOPSIS
    Inicializacao automatizada do Laboratorio de Gerencia de Redes com LibreNMS
#>
if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot

Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "    Laboratorio de Gerencia de Redes - LibreNMS e Docker        " -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# 1. Verifica se o Docker esta em execucao
Write-Host "[1/6] Verificando Docker e Docker Compose..." -ForegroundColor Yellow
$dockerCheck = docker info 2>&1
if ($LASTEXITCODE -ne 0) {
    Write-Host "`n[ERRO] O Docker nao esta em execucao ou nao esta instalado!" -ForegroundColor Red
    Write-Host "Por favor, inicie o Docker Desktop e tente novamente.`n" -ForegroundColor Yellow
    exit 1
}

# Funcao de teste de porta TCP local
function Test-Port([int]$Port) {
    $listener = $null
    try {
        $listener = [System.Net.Sockets.TcpListener]::new([System.Net.IPAddress]::Loopback, $Port)
        $listener.ExclusiveAddressUse = $true
        $listener.Start()
        return $true
    } catch {
        return $false
    } finally {
        if ($listener) { $listener.Stop() }
    }
}

function Get-CurrentPort {
    try {
        $ps = docker compose ps --status running -q librenms 2>$null
        if (-not [string]::IsNullOrWhiteSpace("$ps")) {
            $mapping = docker compose port librenms 8000 2>$null
            if ("$mapping" -match '127\.0\.0\.1:(\d+)') {
                return [int]$Matches[1]
            }
        }
    } catch {}
    return 0
}

# 2. Verifica se o laboratorio ja esta em execucao
$current = Get-CurrentPort
if ($current -gt 0) {
    $url = "http://127.0.0.1:$current"
    Write-Host "`n[INFO] O LibreNMS ja esta em execucao em $url" -ForegroundColor Green
    Write-Host "Abrindo navegador..." -ForegroundColor Cyan
    Start-Process $url
    exit 0
}

# 3. Deteccao e selecao da porta web
Write-Host "[2/6] Verificando portas TCP disponiveis..." -ForegroundColor Yellow
$freePorts = @(18080..18180 | Where-Object { Test-Port $_ } | Select-Object -First 10)
if ($freePorts.Count -eq 0) {
    Write-Host "[ERRO] Nao foi possivel encontrar portas livres na faixa 18080-18180." -ForegroundColor Red
    exit 1
}

$defaultPort = $freePorts[0]
Write-Host "Portas livres sugeridas: $($freePorts -join ', ')" -ForegroundColor Gray
Write-Host "Porta recomendada: $defaultPort" -ForegroundColor Green

$port = 0
do {
    $raw = Read-Host "Digite a porta desejada [Pressione ENTER para usar $defaultPort]"
    if ([string]::IsNullOrWhiteSpace($raw)) {
        $port = $defaultPort
        $valid = $true
    } else {
        $parsed = 0
        $valid = [int]::TryParse($raw.Trim(), [ref]$parsed) -and $parsed -ge 1024 -and $parsed -le 65535
        if ($valid) {
            $valid = Test-Port $parsed
            if ($valid) {
                $port = $parsed
            } else {
                Write-Host "A porta $parsed ja esta ocupada por outro servico. Escolha outra." -ForegroundColor Red
            }
        } else {
            Write-Host "Porta invalida. Digite um numero entre 1024 e 65535." -ForegroundColor Red
        }
    }
} until ($valid)

Write-Host "Porta selecionada: $port" -ForegroundColor Green

# 4. Atualiza o arquivo .env
$envFile = Join-Path $PSScriptRoot '.env'
$lines = @()
if (Test-Path $envFile) {
    $lines = @(Get-Content $envFile | Where-Object { $_ -notmatch '^\s*(export\s+)?LIBRENMS_PORT\s*=' })
}
$lines += "LIBRENMS_PORT=$port"
[IO.File]::WriteAllLines($envFile, [string[]]$lines, [Text.UTF8Encoding]::new($false))
$env:LIBRENMS_PORT = "$port"

# 5. Inicia os containers
Write-Host "`n[3/6] Construindo e iniciando containers Docker..." -ForegroundColor Yellow
docker compose up -d --build
if ($LASTEXITCODE -ne 0) {
    Write-Host "[ERRO] Falha ao iniciar os containers Docker." -ForegroundColor Red
    exit 1
}

$url = "http://127.0.0.1:$port"
Write-Host "`n[4/6] Aguardando inicializacao do LibreNMS em $url ..." -ForegroundColor Yellow
$ready = $false
for ($i = 0; $i -lt 45; $i++) {
    try {
        $response = Invoke-WebRequest -Uri $url -UseBasicParsing -TimeoutSec 3 -ErrorAction SilentlyContinue
        if ($response -and $response.StatusCode -lt 500) {
            $ready = $true
            break
        }
    } catch {
        # Aguarda o servico responder
    }
    Start-Sleep -Seconds 3
    Write-Host -NoNewline "."
}
Write-Host ""

if (-not $ready) {
    Write-Host "[AVISO] O servico demorou mais que o esperado, tentando configuracao..." -ForegroundColor Yellow
}

# 6. Configuracao automatizada do LibreNMS ("magica" zero-touch)
Write-Host "`n[5/6] Aplicando configuracoes automaticas no LibreNMS..." -ForegroundColor Yellow

# Remove flag de instalador web para abrir direto no login
docker compose exec -T librenms sh -c "sed -i '/^INSTALL=/d' /opt/librenms/.env /data/.env 2>/dev/null" 2>$null

# Configura base_url
docker compose exec -T librenms lnms config:set base_url "$url" 2>$null

# Cria usuario administrador (idempotente)
docker compose exec -T librenms lnms user:add admin --password="GerenciaLab@2026!" --role=admin 2>$null

# Prime o scheduler cache
docker compose exec -T --user librenms librenms php /opt/librenms/artisan schedule:run 2>$null

# Cadastra dispositivos do laboratorio
docker compose exec -T librenms lnms device:add firewall --v2c -c laboratorio 2>$null
docker compose exec -T librenms lnms device:add servidor1 --v2c -c laboratorio 2>$null
docker compose exec -T librenms lnms device:add servidor2 --v2c -c laboratorio 2>$null

# Dispara descoberta inicial em segundo plano
docker compose exec -T -d --user librenms librenms php /opt/librenms/discovery.php -h all 2>$null

Write-Host "`n[6/6] Finalizado com sucesso!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  LABORATORIO DE GERENCIA DE REDES PRONTO!" -ForegroundColor Green
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "  URL de Acesso:   $url" -ForegroundColor White
Write-Host "  Usuario Admin:   admin" -ForegroundColor White
Write-Host "  Senha Admin:     GerenciaLab@2026!" -ForegroundColor White
Write-Host "  Comunidade SNMP: laboratorio (v2c)" -ForegroundColor White
Write-Host "  Dispositivos:    firewall (172.28.0.254), servidor1 (172.28.0.11), servidor2 (172.28.0.12)" -ForegroundColor White
Write-Host "================================================================" -ForegroundColor Cyan
Write-Host "Abrindo o navegador automaticamente..." -ForegroundColor Yellow

Start-Sleep -Seconds 1
Start-Process $url
