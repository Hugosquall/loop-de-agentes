# Loop de agentes

Dois agentes de modelos diferentes em loop: um especifica e revisa, o outro implementa e corrige. Um script passa o bastão entre eles até a revisão fechar, outro roda a etapa de segurança, e você só entra em dois portões.

Este repositório tem os scripts, os modelos de arquivo e um exemplo pequeno para rodar.

```text
        ┌──────────────────────────┐
        │ EU                       │
        │ problema e prioridade    │
        └────────────┬─────────────┘
                     ▼
          ESCALAÇÃO: quem refina e quem implementa
                     ▼
        ┌──────────────────────────┐
        │ REFINADOR ESPECIFICA     │
        │ pergunta, planeja,       │
        │ fecha critério de aceite │
        └────────────┬─────────────┘
                     ▼
          PORTÃO 1: eu aprovo o pacote
                     ▼
        ┌──────────────────────────┐
  ┌────►│ IMPLEMENTADOR            │
  │     │ contesta, testa,         │
  │     │ codifica, registra       │
  │     └────────────┬─────────────┘
  │                  ▼
  │     ┌──────────────────────────┐
  │     │ REFINADOR REVISA         │
  │     │ só leitura, reproduz,    │
  │     │ tenta quebrar            │
  │     └─────┬──────────────┬─────┘
  │   BLOCKED │              │ outro veredito
  └───────────┘              ▼
  (até o teto)  ┌──────────────────────────┐
                │ AUDITOR DE SEGURANÇA     │
                │ dependências, código,    │
                │ pentest se o risco pedir │
                └────────────┬─────────────┘
                             ▼
                PORTÃO 2: ok final e deploy
```

Achado de segurança confirmado volta para o implementador pelo mesmo loop.

## O que tem aqui

| Caminho | O que é |
|---|---|
| `loop.sh` | Implementa, revisa e corrige até fechar ou bater o teto de rodadas |
| `seguranca.sh` | Etapa de segurança: dependências e auditoria de código |
| `check_loop.sh` | Confere a lógica dos dois scripts com agentes falsos, sem gastar modelo |
| `modelos/` | Pacote, ledger, achado e os prompts do especificador e do maestro |
| `exemplo/` | Uma tarefa pequena pronta para rodar, com o resultado de uma rodada real |
| `docs/` | [O fluxo](docs/fluxo.md), [comandos](docs/comandos.md), [segurança](docs/seguranca.md), [maestro](docs/maestro.md) e [problemas conhecidos](docs/problemas.md) |

## O que você precisa

- macOS ou Linux com `bash` e `git`.
- Node.js, para o exemplo e para a auditoria de dependências. Testado com Node 22 e npm 10.
- Dois agentes de linha de comando, já autenticados: [Claude Code](https://claude.com/claude-code) (`claude`) e [Codex](https://github.com/openai/codex) (`codex`). Testado com Claude Code 2.1.296 e codex-cli 0.162.1.
- Opcional: Ollama ou LM Studio, para usar um modelo local numa das vagas.

O loop gasta das duas assinaturas. O teto de rodadas existe por isso.

## Começo rápido

1. Confira os scripts sem gastar modelo:

```bash
./check_loop.sh
```

2. Entre no exemplo e leia o pacote em `docs/handoff/parse-price.md`:

```bash
cd exemplo
```

3. Rode o loop. Sem variável, o Codex revisa e o Claude implementa:

```bash
../loop.sh parse-price
```

4. Leia o parecer que o script indicar, em `docs/qa/`.

5. Rode a etapa de segurança:

```bash
AUDITA=codex IMPLEMENTA=claude ../seguranca.sh parse-price
```

O aceite continua sendo seu. Nenhum dos scripts faz commit, push, PR, merge ou deploy.

## No seu projeto

1. Copie `loop.sh`, `seguranca.sh` e `check_loop.sh` para a raiz do seu repositório.
2. Abra uma conversa com o agente que vai refinar e cole [o prompt do especificador](modelos/prompt-especificador.md). Ele entrevista você e escreve `docs/handoff/<tarefa>.md` no [modelo de pacote](modelos/pacote.md).
3. Leia e aprove o pacote. Esse é o portão 1.
4. Rode `./loop.sh <tarefa>`.
5. Quando fechar, rode `./seguranca.sh <tarefa>`.
6. Leia os pareceres e dê o ok final. Esse é o portão 2.

Se o seu projeto não é Node, veja [como adaptar](docs/comandos.md#adaptar-para-outra-linguagem).

Comece na mão: rode uma tarefa pequena levando os arquivos você mesmo, antes de confiar no script.

## Trocar quem faz o quê

```bash
REFINA=claude IMPLEMENTA=codex ./loop.sh minha-tarefa
```

```bash
REFINA=claude IMPLEMENTA=local MODELO_LOCAL=nome-do-modelo ./loop.sh minha-tarefa
```

As duas vagas precisam de agentes diferentes. Todas as variáveis e os códigos de saída estão em [comandos](docs/comandos.md).

## O que já foi testado

Estado em 10/11/2026, em macOS.

| O quê | Estado |
|---|---|
| Lógica dos scripts | 30 casos no `check_loop.sh`, com agentes falsos |
| Loop com Codex revisando e Claude implementando | Rodado de verdade no exemplo |
| Loop com Claude revisando e Codex implementando | Rodado de verdade uma vez, numa versão anterior do script |
| Segurança, camada 0 | Rodada de verdade: bloqueou uma dependência vulnerável posta de propósito |
| Segurança, camada 1 com Codex auditando | Rodada de verdade no exemplo |
| Volta da correção com `CORRIGE` | Só com agentes falsos |
| Claude como auditor | Só com agentes falsos |
| Modelo local | Só com agentes falsos |
| Maestro | Desenhado, sem rodada completa |
| Projeto real grande | Ainda não |

A rodada guardada em `exemplo/resultado/` é de 10/11/2026, com a versão atual dos scripts:

| Etapa | Resultado | Tempo |
|---|---|---|
| Loop, rodada 1 | BLOCKED: o revisor achou perda de precisão em valor muito grande, que os 6 testes do implementador não cobriam | |
| Loop, rodada 2 | PASS, com 8 testes passando | 8 min no total |
| Segurança | PASS_WITH_RISK: nenhuma falha confirmada e uma suspeita, entrada sem limite de tamanho | 4 min |

O tempo varia muito. Numa execução anterior da mesma tarefa, com a mesma escalação, o loop levou 27 minutos.

## Cuidados

- Revisor que escreve no repositório deixa de ser revisor. Mantenha em somente leitura.
- Dado simulado não prova integração real. Leia no parecer o que não foi conferido.
- Auditoria de segurança feita por IA aponta suspeita. Reproduza antes de corrigir.
- Nada de segredo no repositório: os agentes leem tudo o que está na pasta.
- O veredito fecha a rodada. Quem aceita no projeto é você.

## De onde veio

Fluxo do [@hugodevqa](https://www.instagram.com/hugodevqa/). O passo a passo dos outros fluxos está em [hugo-ia-devs.vercel.app](https://hugo-ia-devs.vercel.app/).

## Licença

[MIT](LICENSE).
