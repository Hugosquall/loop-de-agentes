# Exemplo: parse-price

Uma tarefa pequena para ver o loop funcionando: uma função que converte preço em reais para centavos.

## O que tem aqui

| Caminho | O que é |
|---|---|
| `docs/handoff/parse-price.md` | O pacote para implementar, já aprovado |
| `package.json` | Só o comando de teste (`node --test`), sem dependência |
| `resultado/` | O que uma rodada real deixou: código, testes, ledger e pareceres |

## Rodar

```bash
../loop.sh parse-price
```

```bash
AUDITA=codex IMPLEMENTA=claude ../seguranca.sh parse-price
```

O loop cria `src/`, `test/` e `docs/qa/` nesta pasta. Para repetir do zero, apague esses três.

## Ler o resultado de uma rodada real

Em `resultado/`, nesta ordem:

1. `docs/qa/parse-price-ledger.md`: o que o implementador fez em cada rodada.
2. `docs/qa/parse-price-review-r1.md` em diante: o parecer de cada rodada.
3. `docs/qa/parse-price-seguranca.md`: o parecer de segurança.
4. `saida-do-terminal.txt`: o que os dois scripts imprimiram.

Os arquivos são os que os agentes escreveram. Só os caminhos da máquina foram trocados por caminhos relativos. Os comandos citados nos pareceres são os que cada agente rodou naquela máquina, então alguns usam ferramentas que você pode não ter.
