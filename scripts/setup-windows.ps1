# Execute em PowerShell, a partir da raiz do projeto. Nao requer permissao de administrador.
$ErrorActionPreference = 'Stop'
Set-Location (Split-Path -Parent $PSScriptRoot)
if (-not (Get-Command py -ErrorAction SilentlyContinue)) {
    throw 'Python Launcher (py) nao encontrado. Instale Python 3.11+ e marque Add to PATH.'
}
py -3 -m venv .venv
$python = Join-Path (Get-Location) '.venv\Scripts\python.exe'
& $python -m pip install --upgrade pip
& $python -m pip install -e .
& $python -m unittest discover -s tests -v
if ($LASTEXITCODE -ne 0) { throw 'Testes falharam' }
Write-Host 'Ambiente instalado; testes executados. Use scripts/demo-windows.ps1 para gerar evidencias.'
