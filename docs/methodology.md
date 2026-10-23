# Metodologia auditável

## 1. Cadastrar contrato de dados
Registrar origem, sistema proprietário, objeto, chave composta, tipos, normalização, classificação LGPD, políticas de retenção e semântica de exclusão lógica.

## 2. Definir linha de base confiável
Foto transacionalmente consistente, timestamp UTC, watermark Kafka/LSN CDC, versão de esquema e pipeline, contagem, hash em árvore ou por partição, assinatura em domínio independente; reter base anterior conforme política aprovada. Estabelecer confiança inicial com dupla validação: uma foto posterior não comprova autenticidade retroativamente.

## 3. Comparar estados e eventos
R1: chave comum + diferença de campos. R2: chave apenas depois. R3: chave apenas antes. R4: replay deterministicamente controlado da mesma entrada com mesma versão de código/contrato e checagem de saída esperada por camada. Distinguem-se correção autorizada, reprocessamento e incidente.

## 4. Validar legitimidade
Correlacionar diferenças com CDC completo, logs imutáveis, tickets, aprovações, assinaturas de deploy, IAM e janela operacional. Estados: autorizado, suspeito, inconclusivo. Diferença não equivale a fraude.

## 5. Produzir evidência
ID de execução, dataset, origem, instante consistente, fingerprints, IDs de transação pseudonimizados, versão do código e contrato, versões de chaves, justificativa, proveniência e verificação de integridade das evidências.

## 6. Hipóteses que exigem resolução
CDC incompleto, clock skew, atrasos em streaming, mudança de PK, duplicidade, erros de normalização, snapshots inconsistentes, corrupção anterior à baseline, falso-negativo entre fotos, exclusão lógica, retificação e políticas de backup.

## 7. Critérios iniciais de aceite para POC
Fixtures com 1 registro alterado, 1 inserido, 1 excluído e 1 igual; execução offline reproduzível; nenhuma credencial; zero escrita na origem; classificação automática limitada à detecção, não imputação de fraude.
