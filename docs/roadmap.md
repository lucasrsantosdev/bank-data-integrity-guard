# Roadmap de maturidade

- **M0 — atual:** prova de conceito local CSV com R1/R2/R3 e testes; sem integração corporativa.
- **M1 — contrato:** schema registry, canonização por tipo, PK composta, snapshots consistentes, casos negativos.
- **M2 — evidência:** manifesto, cadeia hash, assinatura, WORM, auditoria de acessos e recuperação.
- **M3 — eventos:** CDC e replay; reconciliar fotos vs todas as mudanças entre instantes.
- **M4 — arquitetura medalhão:** validar R4 em Python, SQL, Spark/PySpark; extensão Airflow/Kafka.
- **M5 — controles financeiros:** ledger e idempotência com invariantes bancários aprovados.
- **M6 — piloto:** ambiente segregado, autorização jurídica/segurança, monitoramento e relatório de eficácia.

Métricas futuras: cobertura de tabelas críticas, latency-to-detect, taxa de falso positivo, eventos sem prova de autorização, lacunas de CDC, custo por terabyte.
