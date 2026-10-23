# Somente dados ficticios. Manifestos locais sao PROVA DE CONCEITO, nao WORM.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
$python = Join-Path (Get-Location) '.venv\Scripts\python.exe'
if (-not (Test-Path $python)) { throw 'Execute scripts/setup-windows.ps1 primeiro' }
New-Item -ItemType Directory -Force -Path 'artifacts\demo' | Out-Null
# Chave efemera exclusiva desta execucao. Nao suba a chave no Git.
$bytes = [byte[]]::new(32)
[System.Security.Cryptography.RandomNumberGenerator]::Fill($bytes)
$env:BANKGUARD_HMAC_KEY = [Convert]::ToBase64String($bytes)
try {
    $run = Get-Date -Format 'yyyyMMdd-HHmmss-ffff'
    $beforeManifest = "artifacts/demo/before-$run.json"
    $afterManifest = "artifacts/demo/after-$run.json"
    $report = "artifacts/demo/report-$run.json"
    & $python -m bankguard.cli capture examples/before.csv $beforeManifest --key transaction_id
    if ($LASTEXITCODE -ne 0) { throw 'Falha capturando estado inicial' }
    & $python -m bankguard.cli capture examples/after.csv $afterManifest --key transaction_id
    if ($LASTEXITCODE -ne 0) { throw 'Falha capturando estado posterior' }
    & $python -m bankguard.cli compare examples/before.csv examples/after.csv --key transaction_id --before-manifest $beforeManifest --after-manifest $afterManifest --output $report
    if ($LASTEXITCODE -ne 0) { throw 'Comparacao falhou' }
    Write-Host "Relatorio: $report"
    Write-Warning 'Chave efemera sera descartada. Manifestos nao poderao ser verificados em outra sessao.'
} finally {
    Remove-Item Env:BANKGUARD_HMAC_KEY -ErrorAction SilentlyContinue
}
