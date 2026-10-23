# Bank Data Integrity Guard (BDIG)

**Status: protótipo local demonstrável — sem IA/LLM, sem dados reais e sem integração com bancos.**

Motor determinístico de auditoria de integridade para demonstrar comparação de duas fotografias de transações financeiras fictícias. Inspirado em desafios de pipelines de dados Raw/Bronze → Silver → Gold, com plano de expansão para SQL, Python, PySpark/Spark, Kafka, Airflow e APIs.

## Princípios

- **Zero LLM/IA:** regras rastreáveis, testáveis e reproduzíveis.
- **Dados sintéticos apenas:** não carregar informações de MAPFRE, Santander, Target ou clientes.
- **Isolamento:** nenhuma conexão bancária ou credencial corporativa.
- **Zero confiança implícita:** a fotografia confiável deve vir de captura e custódia independentes.
- **Evidências ≠ prova de fraude:** mudanças legítimas e adulterações exigem investigação distinta.

## Componentes e status

| Componente | Implementação atual |
|---|---|
| Python 3.11+ e CSV | Sim |
| R1 modificação (chave igual / campos diferentes) | Sim |
| R2 inclusão (chave nova) | Sim |
| R3 exclusão (chave ausente) | Sim |
| Proteção contra chave duplicada e schema divergente | Sim |
| Hash SHA-256 do CSV + manifesto HMAC | Sim (demonstração) |
| R4 auditoria transformação Raw/Silver/Gold | Não (planejado) |
| CDC, Spark, Kafka, Airflow, APIs, WORM | Não (planejado) |

## Arquitetura

Consulte [diagrama Mermaid e modelo de ameaças](docs/architecture.md) e [plano por fases](docs/implementation-plan.md).

## Windows / PowerShell — passo a passo

Pré-requisitos: **Windows + PowerShell 7 recomendado**, **Python 3.11+** com `py` disponível e Git. No PowerShell abra a pasta do projeto.

```powershell
# Descompacte o ZIP numa pasta de trabalho e entre nela
cd .\bank-data-integrity-guard

# Configura Python e executa testes
pwsh -NoProfile -File .\scripts\setup-windows.ps1

# Captura dois manifests HMAC de dados fictícios, verifica e compara
pwsh -NoProfile -File .\scripts\demo-windows.ps1
```

Se já estiver no PowerShell 7, também é possível rodar `.\scripts\setup-windows.ps1` e `.\scripts\demo-windows.ps1`. Caso use Windows PowerShell 5.1, instale `pwsh` 7 para suportar a geração de chave aleatória do exemplo.

**Resultado esperado:** TX002 alterada (R1), TX004 incluída (R2), TX003 excluída (R3), TX001 preservada. Report JSON em `artifacts/demo`, ignorado pelo Git.

**Observação sobre chaves:** `demo-windows.ps1` cria chave nova e a apaga no fim; manifestos não serão verificáveis após encerrar a execução. Em produção, é obrigatório um serviço de chaves (KMS/HSM), política de rotação e cadeia de custódia independente. Não colocar segredos no Git.

## Execução manual (sem scripts)

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
.\.venv\Scripts\python.exe -m bankguard.cli compare examples/before.csv examples/after.csv --key transaction_id --output artifacts/report.json
```

## Publicação GitHub — somente após conferir localmente

```powershell
git init
git branch -M main
git add .
git status
git commit -m "feat: initial deterministic bank integrity guard"
# Crie no GitHub um repositório vazio (não gere README automático)
git remote add origin https://github.com/SEU_USUARIO/bank-data-integrity-guard.git
git push -u origin main
```

Verifique antes do commit que `git status` não inclui chaves, dados privados, `.venv`, relatórios ou artefatos. Os comandos acima **não executam publicação automaticamente**.

## Estrutura

```text
bank-data-integrity-guard/
├── src/bankguard/{core.py,evidence.py,cli.py}
├── tests/{test_core.py,test_evidence.py}
├── examples/{before.csv,after.csv}
├── scripts/{setup-windows.ps1,demo-windows.ps1}
├── docs/{architecture.md,implementation-plan.md,methodology.md,security.md,connectors.md,roadmap.md,commercial.md}
├── config/contract.example.json
├── .github/workflows/ci.yml
├── pyproject.toml
└── README.md
```

## Limites de segurança da POC

A verificação valida conteúdo de arquivos comparado ao manifesto **somente se a chave HMAC for confiável e estiver protegida**. Não cria snapshots transacionalmente consistentes nem armazenamento imutável. O arquivo de exemplo tem valores CSV textuais, não modelos financeiros com `Decimal`. Ainda não detecta alterações transitórias, nem distingue alteração legítima de fraude. Não utilizar como sistema de defesa bancária em produção.

## Verificação de qualidade

```powershell
.\.venv\Scripts\python.exe -m unittest discover -s tests -v
```

CI disponível em `.github/workflows/ci.yml` após publicação. Etapas futuras têm critérios de aceite em `docs/implementation-plan.md`.

## Licença e uso comercial

Licença ainda não selecionada. Antes de distribuir ou comercializar, definir licença, autoria, estratégia de propriedade intelectual, política de segurança e requisitos contratuais/regulatórios.
#
