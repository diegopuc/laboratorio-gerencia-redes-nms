if (Test-Path variable:PSNativeCommandUseErrorActionPreference) {
    $PSNativeCommandUseErrorActionPreference = $false
}
$ErrorActionPreference = 'Continue'
Set-Location $PSScriptRoot

$ps = docker compose ps --status running -q librenms 2>$null
if (-not [string]::IsNullOrWhiteSpace("$ps")) {
    $m = docker compose port librenms 8000 2>$null
    if ("$m" -match '127\.0\.0\.1:(\d+)') {
        $url = "http://127.0.0.1:$($Matches[1])"
        Write-Host "Abrindo $url no navegador..." -ForegroundColor Green
        Start-Process $url
        exit 0
    }
}
Write-Host "O LibreNMS nao esta em execucao. Inicie com iniciar.bat primeiro." -ForegroundColor Red
