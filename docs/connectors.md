# Plano de conectores (não implementados)

| Tecnologia | Coleta sugerida sem escrita | Consistência/evidência |
|---|---|---|
| PostgreSQL / SQL Server / Oracle | SELECT com snapshot isolation ou export consistente | LSN/SCN, schema e contagem |
| API REST | paginação autenticada com versão/ETag | cursor, request id, assinatura se houver |
| Kafka | consumir tópico autorizado | topic/partition/offset; retenção e schema registry |
| Spark/PySpark | manifestos de entrada/saída e tabelas | job id, commit de tabela, partições, plano |
| Airflow | metadados somente leitura do DAG | DAG/run id, código/versionamento, logs |
| GitHub | commits assinados/fluxo CI/CD | commit SHA, artefato, autorizações, proveniência |
| SQL transformações | hash/versionamento do script e contratos | execução, query id, parâmetros |

Conectores devem falhar de modo seguro quando não houver leitura consistente ou permissão.
