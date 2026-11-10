# Ledger: parse-price

## Rodada 1 — 2026-11-10

**Executor:** claude (handoff `docs/handoff/parse-price.md`)
**Checagem de contradição no pacote:** nenhuma. Entradas, saídas, critérios de aceite e "fora do escopo" são coerentes entre si.

### Arquivos alterados

| Arquivo | Ação |
|---|---|
| `test/parse-price.test.js` | criado (6 testes cobrindo os critérios de aceite) |
| `src/parse-price.js` | criado (`parsePrice`) |
| `docs/qa/parse-price-ledger.md` | criado (este arquivo) |

Nada alterado em `package.json`, `package-lock.json` ou `docs/handoff/`.

### Comandos rodados e saída

1. `npm test` — antes da implementação (RED, esperado):

```
# code: 'ERR_MODULE_NOT_FOUND',
# url: 'file:///.../src/parse-price.js'
not ok 1 - test/parse-price.test.js
# tests 1
# pass 0
# fail 1
```

2. `npm test` — após implementação (GREEN):

```
1..6
# tests 6
# pass 6
# fail 0
```

3. `npm test` — após refactor da regex (prefixo `R$` opcional em vez de alternativa duplicada):

```
1..6
# tests 6
# pass 6
# fail 0
```

### Critérios de aceite

- [x] `parsePrice('R$ 1.234,56') === 123456`
- [x] `parsePrice('1234,56') === 123456`
- [x] `parsePrice('R$10') === 1000`
- [x] `parsePrice('10,5') === 1050`
- [x] `parsePrice('abc')`, `parsePrice('')` e `parsePrice(null)` lançam `TypeError`
- [x] resultado sempre inteiro (aritmética só com inteiros: `reais * 100 + centavos`, sem multiplicar float)
- [x] `npm test` passando
- [x] nada alterado fora de "Pode modificar"

### Decisões

- Regex aceita separador de milhar só em grupos de 3 (`1.234`), ou dígitos sem ponto (`1234`). `1.23` sem vírgula é rejeitado como preço inválido.
- Centavo com 1 dígito (`10,5`) é completado à direita (`50`), conforme critério.
- Entrada com espaços nas pontas é aceita (`trim`). Espaço entre `R$` e número é opcional.

### Pendente / fora desta rodada

- Comandos `git status` e shell composto com `cd` foram bloqueados pela sandbox da sessão. A verificação de "nada alterado fora do permitido" se baseia nos três arquivos escritos nesta sessão, não em `git status`. Recomenda-se o revisor rodar `git status --short` para confirmar.
- Sem commit, push ou PR (conforme autorização).
- Negativos, formato americano e outras moedas: fora de escopo; hoje lançam `TypeError`.

## Rodada 2 — 2026-11-10

**Executor:** claude
**Origem:** `docs/qa/parse-price-review-r1.md` (veredito BLOCKED). Único achado aberto: **CX-01** — perda de precisão acima de `Number.MAX_SAFE_INTEGER` e retorno de `Infinity` para entradas com 309 dígitos.
**Escopo:** só CX-01, dentro de `docs/handoff/parse-price.md`. Nenhum outro achado aberto ou reaberto na review.

### Arquivos alterados

| Arquivo | Ação |
|---|---|
| `test/parse-price.test.js` | +2 testes: limite seguro aceito (`90071992547409,91` → `MAX_SAFE_INTEGER`) e `RangeError` para `…,92`, `…,93` e `'9'.repeat(309)` |
| `src/parse-price.js` | soma em `BigInt`; lança `RangeError` quando centavos > `Number.MAX_SAFE_INTEGER`; só então converte para `Number` |
| `docs/qa/parse-price-ledger.md` | esta seção |

Nada tocado em `package.json`, `package-lock.json` ou `docs/handoff/`.

### Comandos rodados e saída

1. `npm test` — primeira versão do teste (RED inválido). O teste de precisão comparava com o literal `9007199254740993`, que o próprio JS arredonda para `…992`; passou sem testar nada. Teste descartado e reescrito: `…,93` passou a ser caso de `RangeError`, e `…,91` ficou como guarda do limite.

```
ok 6 - preserva centavos até o limite seguro de inteiro (CX-01)
not ok 7 - valor acima do limite seguro lança RangeError em vez de perder precisão (CX-01)
  error: 'Missing expected exception (RangeError).'
# tests 8
# pass 7
# fail 1
```

2. `npm test` — teste reescrito, antes da implementação (RED válido):

```
not ok 7 - valor acima do limite seguro lança RangeError em vez de perder precisão (CX-01)
  location: '.../test/parse-price.test.js:32:1'
  error: 'Missing expected exception (RangeError).'
1..8
# tests 8
# pass 7
# fail 1
```

3. `npm test` — após implementação (GREEN):

```
1..8
# tests 8
# suites 0
# pass 8
# fail 0
# cancelled 0
# skipped 0
# todo 0
# duration_ms 44.584542
```

### Decisões

- **`RangeError`, não `TypeError`, para overflow.** O handoff reserva `TypeError` para "entrada que não é preço". `90071992547409,92` é um preço bem formado que não cabe em centavos inteiros seguros; é erro de faixa. Quem quiser tratar tudo igual captura `Error`.
- **Limite = `Number.MAX_SAFE_INTEGER` em centavos** (≈ R$ 90 trilhões). O handoff exige "resultado sempre inteiro, sem erro de ponto flutuante" e não fixa máximo; esse é o maior valor que cumpre o critério com retorno `number`. Retornar `BigInt` mudaria o contrato (`=== 123456` nos critérios de aceite falharia).
- Aritmética passou de `Number` para `BigInt` só para a soma; conversão para `Number` ocorre depois da checagem, então nunca perde centavo.

### Critérios de aceite (re-conferidos)

- [x] os 4 exemplos positivos e os 3 negativos do handoff — inalterados, passando
- [x] resultado sempre inteiro, sem erro de ponto flutuante — agora garantido em toda a faixa aceita; fora dela lança
- [x] `npm test` passando (8/8)
- [x] nada alterado fora de "Pode modificar" — ver pendência abaixo

### Pendente / fora desta rodada

- **Probe do revisor não reexecutado** (`node --input-type=module -e '...'`): bloqueado pela sandbox da sessão, sem superfície de aprovação. As três entradas do probe (`90071992547409,93`, `'9'.repeat(309)` e o limite `…,91`) estão cobertas literalmente nos testes 6 e 7, que passam. Recomenda-se o revisor rodar o probe; saída esperada: `RangeError` nas duas primeiras e `9007199254740991` na terceira.
- **`git status --short` e `git diff HEAD`** bloqueados pela sandbox, como na rodada 1. Arquivos escritos nesta sessão: só os três da tabela acima. Revisor deve confirmar que `package.json`, `package-lock.json` e `docs/handoff/` seguem iguais ao `HEAD`.
- Sem commit, push ou PR (conforme instrução).
