# Arquitetura de referência — fictícia, sem acesso bancário

```mermaid
flowchart TD
    A[Core bancário fictício / API / eventos] --> B[Captura consistente e CDC - FUTURO]
    B --> C[Raw/Bronze]
    C --> D[Silver]
    D --> E[Gold]
    A --> F[Snapshot confiável + manifesto]
    F --> G[Armazenamento WORM externo - FUTURO]
    C --> H[Motor determinístico]
    D --> H
    E --> H
    G --> H
    I[Metadados SQL / Spark / Airflow / Kafka - FUTURO] --> H
    H --> J[R1 modificação / R2 inclusão / R3 exclusão]
    H --> K[R4 transformação - FUTURO]
    J --> L[Correlacionar CDC + autorizações - FUTURO]
    K --> L
    L --> M[Relatório e evidências]
```

## Limites e ameaças

* **Já implementado:** CSV local, detecção R1-R3, verificação de schema, hashing SHA-256 e manifesto HMAC, sem dependências runtime externas.
* **Não implementado:** R4, captura transacional consistente, CDC, armazenamento WORM, integração com banco/API, cadeia de custódia, autorização corporativa, alerta em tempo real.
* **Condição de confiança:** a referência deve ser capturada por mecanismo independente e validada com chave protegida separadamente. HMAC local sozinho não prova imutabilidade, autenticidade temporal ou identidade do operador.
* **Limite do snapshot:** mudança que ocorre e é revertida entre fotografias passa despercebida sem CDC/audit log.
* **Limite do diff:** divergência não prova adulteração; evento legítimo requer vínculo com razão de negócio e autorização.
* **Risco operacional:** não armazenar CPFs, nomes, contas reais, segredos, dumps ou dados corporativos no repositório.
