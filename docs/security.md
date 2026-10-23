# Segurança por desenho

- Independência da infraestrutura auditada: contas, KMS e logs separados; snapshots e manifestos com retenção imutável e assinaturas verificáveis.
- Coleta somente leitura e com privilégio mínimo; limitar escopo, rate e redes. Proibir DML/DDL nos sistemas alvo.
- Nunca versionar dados bancários pessoais, tokens ou dados produtivos no GitHub; uso de dados sintéticos.
- Autorização explícita antes de testar ambientes reais; revisão de LGPD, sigilo bancário, contrato e retenção.
- Verificar software dependencies: hashes/lockfiles, SBOM, proveniência SLSA, revisão de PR e proteções de branch.
- Falha de confiança: se o plano de controle ou a chave de assinatura foi comprometida, emitir alerta de cadeia de custódia inválida; não apresentar comparação como prova conclusiva.
- Falhas de disponibilidade não equivalem a corrupção; registrar lag, completude e health dos conectores.
- Transparência: controles não construídos não podem ser anunciados como disponíveis.
