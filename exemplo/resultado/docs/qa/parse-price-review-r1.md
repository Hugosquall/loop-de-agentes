VEREDITO: BLOCKED

**CX-01 — ABERTO — Perda de precisão e retorno de `Infinity`**

- **Local:** `src/parse-price.js:18`.
- **Observado:** `parsePrice('90071992547409,93')` retorna `9007199254740992`, perdendo um centavo. `parsePrice('9'.repeat(309))` retorna `Infinity`.
- **Esperado:** preservar exatamente os centavos nas entradas aceitas. Valores não representáveis devem ser rejeitados explicitamente. O handoff exige resultado inteiro sem erro de ponto flutuante e não estabelece limite máximo.
- **Impacto:** corrupção silenciosa do valor e violação do contrato. Os testes existentes verificam somente valores pequenos; a garantia registrada no ledger não se sustenta.
- **Reprodução:** executar na raiz:

```sh
rtk proxy node --input-type=module -e 'import {parsePrice} from "./src/parse-price.js"; console.log(BigInt(parsePrice("90071992547409,93"))); console.log(parsePrice("9".repeat(309)));'
```

Saída observada: `9007199254740992n` e `Infinity`.

**Recomendação:** validar o limite seguro de centavos, adicionar regressões para precisão e overflow e atualizar o ledger.

**Conferido de verdade:**

- Handoff, ledger, implementação, testes e referências à função.
- `git status`, `git diff HEAD` e diff staged: apenas os três arquivos novos autorizados; arquivos protegidos idênticos ao `HEAD`.
- `rtk proxy npm test`: **6/6 passaram**, no Node `v22.23.2`.
- Probes adicionais: **13 entradas válidas, 46 inválidas e 30.000 conversões determinísticas passaram**.
- Duas asserções adicionais sobre precisão e retorno inteiro **falharam**, comprovando CX-01.
- Hashes finais dos seis arquivos iguais aos iniciais: nenhum arquivo alterado durante a revisão.

Não pude comprovar retrospectivamente o ciclo RED/GREEN narrado no ledger; executei a versão atual.  
Risco confirmado: entradas grandes continuam podendo perder centavos ou retornar `Infinity`.