# Comandos

Todos os scripts rodam de dentro do repositório do seu projeto, na pasta que tem `docs/handoff/`.

## check_loop.sh

Confere a lógica dos dois scripts com `claude`, `codex` e `npm` falsos. Não chama modelo nem rede e termina em segundos.

```bash
./check_loop.sh
```

Rode depois de qualquer mudança nos scripts. A última linha diz quantos casos passaram.

## loop.sh

Implementa, revisa e corrige até fechar ou bater o teto de rodadas.

```bash
./loop.sh <tarefa> [teto]
```

| Entrada | Padrão | O que é |
|---|---|---|
| `<tarefa>` | obrigatório | Nome do pacote, sem extensão: lê `docs/handoff/<tarefa>.md` |
| `[teto]` | `3` | Máximo de rodadas nesta execução |
| `REFINA` | `codex` | Quem revisa: `claude`, `codex` ou `local` |
| `IMPLEMENTA` | `claude` | Quem implementa: `claude`, `codex` ou `local` |
| `CORRIGE` | vazio | Caminho de um parecer. Com ele, a primeira rodada já começa corrigindo os achados abertos desse parecer |
| `PROVEDOR_LOCAL` | `ollama` | Provedor do modelo local: `ollama` ou `lmstudio` |
| `MODELO_LOCAL` | vazio | Nome do modelo local |

| Saída | Significa |
|---|---|
| 0 | Fechou com PASS, PASS_WITH_RISK ou NEEDS_HUMAN_QA. O aceite é seu. |
| 1 | Entrada inválida: pacote ausente, agente desconhecido, mesmo agente nas duas vagas ou parecer de `CORRIGE` inexistente |
| 2 | Bateu o teto ainda em BLOCKED |
| 3 | Parecer sem veredito válido na primeira linha |

Exemplos:

```bash
./loop.sh minha-tarefa
```

```bash
REFINA=claude IMPLEMENTA=codex ./loop.sh minha-tarefa
```

```bash
REFINA=claude IMPLEMENTA=local MODELO_LOCAL=nome-do-modelo ./loop.sh minha-tarefa
```

```bash
CORRIGE=docs/qa/minha-tarefa-seguranca.md ./loop.sh minha-tarefa
```

Rodar de novo na mesma tarefa continua a numeração das rodadas. Nenhum parecer antigo é sobrescrito.

## seguranca.sh

Etapa de segurança, depois que o loop fechou e antes do ok final.

```bash
AUDITA=codex IMPLEMENTA=claude ./seguranca.sh <tarefa>
```

| Entrada | Padrão | O que é |
|---|---|---|
| `<tarefa>` | obrigatório | Mesmo nome usado no loop |
| `AUDITA` | `codex` | Quem audita: `claude`, `codex` ou `local` |
| `IMPLEMENTA` | `claude` | Quem implementou. O auditor precisa ser outro. |
| `PROVEDOR_LOCAL`, `MODELO_LOCAL` | como no loop | Só quando `AUDITA=local` |

| Saída | Significa |
|---|---|
| 0 | PASS, PASS_WITH_RISK ou NEEDS_HUMAN_QA |
| 1 | Entrada inválida |
| 2 | BLOCKED: dependência com falha alta ou crítica, ou achado confirmado no código |
| 3 | Não conseguiu concluir: `npm audit` falhou ou o parecer veio sem veredito válido |

O parecer fica em `docs/qa/<tarefa>-seguranca.md`. Quando o bloqueio é no código, o script mostra o comando para devolver ao implementador com `CORRIGE`. Bloqueio de dependência não entra no loop: atualizar dependência é decisão sua.

## O que cada agente pode fazer

O limite de cada agente vem da ferramenta, além do pedido.

| Papel | Claude Code | Codex |
|---|---|---|
| Implementador | `--permission-mode acceptEdits` com `--allowedTools`: lê, edita e roda `npm test` | `-s workspace-write`: escreve só na pasta de trabalho |
| Revisor e auditor | `--disallowedTools` com as ferramentas de edição; lê, roda `npm test`, `git status` e `git diff` | `-s read-only`: lê e executa, não grava no disco |

`--permission-prompts none` faz o Claude sem tela negar o que não está liberado. Sem isso ele fica esperando alguém responder um pedido de permissão e o loop trava.

O modelo local entra pelo próprio Codex, com `--oss`.

## Adaptar para outra linguagem

Os scripts assumem Node. Para outro projeto, troque três pontos:

1. **Comando de teste.** Em `loop.sh` e `seguranca.sh`, troque `Bash(npm test *)` pelo seu comando, por exemplo `Bash(pytest *)`.
2. **Auditoria de dependências.** Em `seguranca.sh`, o bloco da camada 0 lê o JSON do `npm audit`. Troque pela ferramenta da sua linguagem e mantenha a regra: alta ou crítica bloqueia, o resto vira risco, erro da ferramenta para tudo.
3. **Self-check.** Em `check_loop.sh`, o `npm` falso imita esse JSON. Ajuste junto e rode de novo.
