# Pacote para implementar: parse-price

Escalação: refina codex; implementa claude
Objetivo: função `parsePrice(text)` em `src/parse-price.js` que converte um preço em reais, escrito por uma pessoa, em centavos inteiros.
Escopo aprovado:
- Entrada no formato brasileiro: `R$ 1.234,56`, `1234,56`, `R$10`, `10,5`.
- Saída: número inteiro de centavos (`123456`, `123456`, `1000`, `1050`).
- Entrada que não é preço lança `TypeError`.
Fora do escopo: outras moedas, formato americano (`1,234.56`), valores negativos.
Plano por etapas:
1. Teste falhando que cobre os critérios de aceite.
2. Implementação até os testes passarem.
3. Registro da rodada no ledger.
Pode modificar: `src/parse-price.js`, `test/parse-price.test.js`, além do ledger em `docs/qa/`
Não pode alterar: `package.json`, `package-lock.json`, `docs/handoff/`
Critérios de aceite:
- [ ] `parsePrice('R$ 1.234,56') === 123456`
- [ ] `parsePrice('1234,56') === 123456`
- [ ] `parsePrice('R$10') === 1000`
- [ ] `parsePrice('10,5') === 1050`
- [ ] `parsePrice('abc')`, `parsePrice('')` e `parsePrice(null)` lançam `TypeError`
- [ ] o resultado é sempre inteiro, sem erro de ponto flutuante
- [ ] `npm test` passando
- [ ] nada alterado fora de "Pode modificar"
Como comprovar: `npm test`
Referências: nenhuma
Ambiente: pasta local, sem rede. Tudo roda com dado de exemplo.
Autorizações: editar os arquivos liberados e rodar `npm test`. Sem commit, push, PR ou instalação de dependência.
