# Plano de execução faseado

| Fase | Entregável | Critério de aceite | Estado |
|---|---|---|---|
| 0.1 | Comparador determinístico CSV R1-R3 | testes unitários e saída JSON | implementado |
| 0.2 | Manifesto HMAC + integridade CSV | detecção de manipulação do CSV e manifesto, testes | implementado em POC |
| 0.3 | Contrato de schema e tipos (Decimal, timezone, campos nulos) | testes de campos, schema e precisão financeira | planejado |
| 0.4 | Captura consistente + watermark / CDC simulado | captura/replay e detecção de mudanças intermediárias | planejado |
| 0.5 | Raw/Silver/Gold em SQL e PySpark | R4 com execução reproduzível e lineage | planejado |
| 0.6 | Conectores PostgreSQL/API/Kafka/Airflow somente leitura | validação isolada com credenciais mínimas | planejado |
| 1.0 | Evidências WORM, observabilidade, política de autorização | exercícios de ameaça e testes de recuperação | planejado |

Sem integração real ou promessa de homologação bancária. Escopo inicial: transações sintéticas e operações financeiras simuladas.
