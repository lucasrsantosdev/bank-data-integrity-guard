<#
.SYNOPSIS
Auditoria local, somente leitura, do projeto Bank Data Integrity Guard.
.DESCRIPTION
Inventaria arquivos, valida estrutura, contratos, imports Python, testes unitarios,
CI, documentacao e higiene Git. Gera JSON e Markdown para README.
Nao se conecta a bancos, nao envia dados, nao altera codigo e nao executa demo.
.EXAMPLE
pwsh -NoProfile -File .\scripts\audit-project.ps1 -RunTests
#>
[CmdletBinding()]
param(
    [string]$ProjectRoot = (Split-Path -Parent $PSScriptRoot),
    [switch]$RunTests,
    [switch]$CheckGit,
    [switch]$Strict
)
$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest
$root = (Resolve-Path -LiteralPath $ProjectRoot).Path
$outDir = Join-Path $root 'artifacts\audit'
New-Item -ItemType Directory -Path $outDir -Force | Out-Null
$checks = [System.Collections.Generic.List[object]]::new()
function Add-Check([string]$id, [string]$category, [string]$status, [string]$detail) {
    $checks.Add([pscustomobject]@{id=$id;category=$category;status=$status;detail=$detail})
    $tag = switch ($status) { 'PASS' {'OK'} 'FAIL' {'FALHA'} default {'AVISO'} }
    Write-Host "[$tag] $id - $detail"
}
function Test-Required([string]$relative, [string]$id) {
    if (Test-Path -LiteralPath (Join-Path $root $relative) -PathType Leaf) {
        Add-Check $id 'structure' 'PASS' "Presente: $relative"
    } else { Add-Check $id 'structure' 'FAIL' "Ausente: $relative" }
}
function Find-Python {
    $venv = Join-Path $root '.venv\Scripts\python.exe'
    if (Test-Path -LiteralPath $venv) { return @{cmd=$venv;prefix=@()} }
    if (Get-Command py -ErrorAction SilentlyContinue) { return @{cmd='py';prefix=@('-3')} }
    if (Get-Command python -ErrorAction SilentlyContinue) { return @{cmd='python';prefix=@()} }
    return $null
}
function Run-Python([hashtable]$python, [string[]]$arguments) {
    $all = @($python.prefix) + $arguments
    $output = & $python.cmd @all 2>&1 | Out-String
    return @{exit=$LASTEXITCODE;output=$output.Trim()}
}
$required = @(
    @('README.md','STRUCT-README'),@('pyproject.toml','STRUCT-BUILD'),
    @('src/bankguard/core.py','STRUCT-CORE'),@('src/bankguard/evidence.py','STRUCT-EVIDENCE'),
    @('src/bankguard/cli.py','STRUCT-CLI'),@('tests/test_core.py','STRUCT-TEST-CORE'),
    @('tests/test_evidence.py','STRUCT-TEST-EVIDENCE'),
    @('examples/before.csv','STRUCT-EXAMPLE-BEFORE'),@('examples/after.csv','STRUCT-EXAMPLE-AFTER'),
    @('config/contract.example.json','STRUCT-CONTRACT'),@('docs/architecture.md','STRUCT-ARCH'),
    @('docs/methodology.md','STRUCT-METHOD'),@('docs/security.md','STRUCT-SECURITY'),
    @('docs/roadmap.md','STRUCT-ROADMAP'),@('.github/workflows/ci.yml','STRUCT-CI'),
    @('.gitignore','STRUCT-GITIGNORE'),@('scripts/setup-windows.ps1','STRUCT-SETUP'),
    @('scripts/demo-windows.ps1','STRUCT-DEMO')
)
foreach($pair in $required){ Test-Required $pair[0] $pair[1] }
try {
    $contract = Get-Content -LiteralPath (Join-Path $root 'config/contract.example.json') -Raw -Encoding UTF8 | ConvertFrom-Json
    Add-Check 'CONTRACT-JSON' 'contracts' 'PASS' 'Contrato JSON sintaticamente valido'
} catch { Add-Check 'CONTRACT-JSON' 'contracts' 'FAIL' ('Contrato JSON invalido: ' + $_.Exception.Message) }
try {
    $before = Import-Csv -LiteralPath (Join-Path $root 'examples/before.csv')
    $after = Import-Csv -LiteralPath (Join-Path $root 'examples/after.csv')
    $headers1 = @($before[0].PSObject.Properties.Name)
    $headers2 = @($after[0].PSObject.Properties.Name)
    if (($headers1 -join ',') -eq ($headers2 -join ',')) {
        Add-Check 'EXAMPLES-SCHEMA' 'data' 'PASS' ('CSV com colunas consistentes: ' + ($headers1 -join ', '))
    } else { Add-Check 'EXAMPLES-SCHEMA' 'data' 'FAIL' 'Colunas before/after divergem' }
    if ($headers1 -contains 'transaction_id') {
        $idsA = @($before | ForEach-Object { $_.transaction_id })
        $idsB = @($after | ForEach-Object { $_.transaction_id })
        if ((@($idsA | Select-Object -Unique).Count -eq $idsA.Count) -and (@($idsB | Select-Object -Unique).Count -eq $idsB.Count)) {
            Add-Check 'EXAMPLES-KEY' 'data' 'PASS' 'Chaves transaction_id unicas nos exemplos'
        } else { Add-Check 'EXAMPLES-KEY' 'data' 'FAIL' 'Existem chaves duplicadas nos exemplos' }
    } else { Add-Check 'EXAMPLES-KEY' 'data' 'FAIL' 'Falta transaction_id' }
} catch { Add-Check 'EXAMPLES-CSV' 'data' 'FAIL' ('Falha lendo exemplos: ' + $_.Exception.Message) }
$readme = Get-Content (Join-Path $root 'README.md') -Raw -Encoding UTF8
foreach ($entry in @(@('README-ARCH','arquitetura'),@('README-TEST','teste'),@('README-SEC','seguran'),@('README-LIMIT','limita'))) {
    if ($readme -match $entry[1]) { Add-Check $entry[0] 'documentation' 'PASS' "README menciona $($entry[1])" }
    else { Add-Check $entry[0] 'documentation' 'WARN' "README deveria abordar $($entry[1])" }
}
$gitignore = Get-Content (Join-Path $root '.gitignore') -Raw -Encoding UTF8
foreach($pattern in @('.venv/','.env','artifacts/','*.key')) {
    if ($gitignore.Contains($pattern)) { Add-Check "IGNORE-$pattern" 'security' 'PASS' "Git ignora $pattern" }
    else { Add-Check "IGNORE-$pattern" 'security' 'FAIL' "Git deveria ignorar $pattern" }
}
$gitDir = Join-Path $root '.git'
if ($CheckGit) {
    if (-not (Test-Path $gitDir)) { Add-Check 'GIT-REPO' 'git' 'WARN' 'Repositorio ainda nao inicializado' }
    elseif (-not (Get-Command git -ErrorAction SilentlyContinue)) { Add-Check 'GIT-CLI' 'git' 'WARN' 'Git indisponivel' }
    else {
        # Nao imprimir lista de arquivos tracked para evitar nomes potencialmente sensiveis no relatorio.
        $tracked = & git -C $root ls-files -- .env '*.key' 'secrets/*' 'private/*' 'artifacts/*' 2>$null
        if ($LASTEXITCODE -ne 0) { Add-Check 'GIT-TRACKED' 'git' 'WARN' 'Nao foi possivel consultar o indice Git' }
        elseif ($tracked) { Add-Check 'GIT-TRACKED' 'git' 'FAIL' 'Itens potencialmente sensiveis rastreados no Git; revise com git ls-files' }
        else { Add-Check 'GIT-TRACKED' 'git' 'PASS' 'Nenhum dos caminhos sensiveis conhecidos no indice Git' }
    }
} else { Add-Check 'GIT-TRACKED' 'git' 'WARN' 'Nao executado; use -CheckGit' }
$python = Find-Python
if ($null -eq $python) { Add-Check 'PYTHON' 'runtime' 'WARN' 'Python nao localizado' }
else {
    $version = Run-Python $python @('--version')
    if ($version.exit -eq 0) { Add-Check 'PYTHON' 'runtime' 'PASS' $version.output }
    else { Add-Check 'PYTHON' 'runtime' 'WARN' 'Falha ao verificar versao do Python' }
    $allPy = @(Get-ChildItem (Join-Path $root 'src'), (Join-Path $root 'tests') -Recurse -File -Filter '*.py' | Select-Object -ExpandProperty FullName)
    # Compilacao em memoria sem criar __pycache__ nem modificar arquivos do projeto.
    $pyCode = 'import pathlib,sys; [compile(pathlib.Path(p).read_bytes(),p,"exec") for p in sys.argv[1:]]; print("Syntax OK: "+str(len(sys.argv)-1)+" files")'
    $syntax = Run-Python $python (@('-c',$pyCode) + $allPy)
    if ($syntax.exit -eq 0) { Add-Check 'PYTHON-SYNTAX' 'code' 'PASS' $syntax.output }
    else { Add-Check 'PYTHON-SYNTAX' 'code' 'FAIL' 'Erros de sintaxe Python; execute localmente para obter detalhes' }
    if ($RunTests) {
        $old = $env:PYTHONPATH
        try {
            $env:PYTHONPATH = Join-Path $root 'src'
            Push-Location $root
            try { $tests = Run-Python $python @('-m','unittest','discover','-s','tests','-v') }
            finally { Pop-Location }
        } finally { $env:PYTHONPATH = $old }
        $outFile = Join-Path $outDir 'unittest-output.txt'
        [System.IO.File]::WriteAllText($outFile, $tests.output + [Environment]::NewLine, [System.Text.Encoding]::UTF8)
        $summary = if ($tests.output -match 'Ran\s+\d+\s+tests?') { $Matches[0] } else { 'consultar unittest-output.txt' }
        if ($tests.exit -eq 0) { Add-Check 'UNITTEST' 'tests' 'PASS' "$summary, exit 0" }
        else { Add-Check 'UNITTEST' 'tests' 'FAIL' "$summary, exit $($tests.exit); ver unittest-output.txt" }
    } else { Add-Check 'UNITTEST' 'tests' 'WARN' 'Nao executado; use -RunTests' }
}
$inventory = @(Get-ChildItem -LiteralPath $root -Recurse -File -Force | Where-Object {
    $r = $_.FullName.Substring($root.Length).TrimStart('\','/')
    $r -notmatch '(^|[\\/])(\.git|\.venv|__pycache__|artifacts)([\\/]|$)'
} | ForEach-Object {
    $relative = $_.FullName.Substring($root.Length).TrimStart('\','/').Replace('\','/')
    [pscustomobject]@{path=$relative;size_bytes=$_.Length;sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
} | Sort-Object path)
$stamp = Get-Date -Format 'yyyy-MM-ddTHH:mm:sszzz'
$summary = [ordered]@{PASS=@($checks | Where-Object status -eq 'PASS').Count; WARN=@($checks | Where-Object status -eq 'WARN').Count; FAIL=@($checks | Where-Object status -eq 'FAIL').Count}
$report = [ordered]@{
    project='Bank Data Integrity Guard'; audit_version='0.1'; date_local=$stamp
    offline=$true; synthetic_data_only=$true
    checks=@($checks); summary=$summary; inventory=$inventory
    notes=@('Hashes do inventario nao constituem atestado independente: relatorio e arquivos estao no mesmo ambiente.', 'Integracoes com bancos, CDC e armazenamento WORM nao foram verificadas por este script.', 'Revisao humana e necessaria antes de usar conclusoes no README.')
}
$jsonPath=Join-Path $outDir 'architecture-audit.json'
$mdPath=Join-Path $outDir 'architecture-audit.md'
$report | ConvertTo-Json -Depth 9 | Set-Content -LiteralPath $jsonPath -Encoding UTF8
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Auditoria local da arquitetura — BDIG')
$lines.Add('')
$lines.Add("Data local: $stamp. Escopo: repositorio local, dados sinteticos, sem acesso externo.")
$lines.Add('')
$lines.Add("**Resultado:** $($summary.PASS) PASS | $($summary.WARN) WARN | $($summary.FAIL) FAIL")
$lines.Add('')
$lines.Add('| ID | Area | Resultado | Evidencia / limitacao |')
$lines.Add('|---|---|---|---|')
foreach($c in $checks) {
    $detail=([string]$c.detail).Replace('|','/').Replace("`r",' ').Replace("`n",' ')
    $lines.Add("| $($c.id) | $($c.category) | $($c.status) | $detail |")
}
$lines.Add('')
$lines.Add("Arquivos inventariados: $($inventory.Count). Hashes SHA-256 e tamanhos no architecture-audit.json.")
$lines.Add('')
$lines.Add('## Limites')
$lines.Add('')
$lines.Add('- Auditoria de estrutura nao equivale a pentest, SAST ou certificacao bancaria.')
$lines.Add('- R4, Spark, Kafka, Airflow, CDC e ambiente real nao sao homologados por este relatorio.')
$lines.Add('- Os hashes do inventario precisam ser ancorados externamente para servir como evidencia independente.')
$lines.Add('- Conferir findings e nao publicar nomes de arquivos sensiveis antes do commit.')
$lines | Set-Content -LiteralPath $mdPath -Encoding UTF8
Write-Host "`nRelatorios: $jsonPath e $mdPath"
Write-Host "Resumo: $($summary.PASS) PASS, $($summary.WARN) WARN, $($summary.FAIL) FAIL"
if ($summary.FAIL -gt 0 -or ($Strict -and $summary.WARN -gt 0)) { exit 1 }
exit 0
