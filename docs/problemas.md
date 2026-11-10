# Problemas conhecidos

O que apareceu nos testes e como resolver.

## O loop fica parado e o implementador não escreve nada

O Claude sem tela pediu permissão para um comando e ficou esperando resposta. O script já passa `--permission-prompts none`, que nega o que não está liberado. Se você editou a chamada do `claude`, confira se a flag continua lá.

## Rodando de dentro de outra sessão do Claude Code

Os testes daqui foram disparados de dentro de uma sessão do Claude Code, com o ambiente limpo:

```bash
env -i HOME="$HOME" PATH="$PATH" USER="$USER" LOGNAME="$USER" SHELL=/bin/zsh TERM=xterm-256color LANG=en_US.UTF-8 ./loop.sh minha-tarefa
```

De um terminal normal não precisa disso.

## "Parecer sem veredito válido" (saída 3)

O revisor não começou a resposta pela linha de veredito, ou escreveu um veredito que não existe. Abra o parecer indicado, leia o que ele disse e rode de novo. O script não tenta adivinhar.

## "Camada 0 não rodou" (saída 3)

O `npm audit` falhou. O motivo mais comum é não ter `package-lock.json`:

```bash
npm install --package-lock-only
```

## Está lento

Nos testes, a mesma função simples levou de 8 a 30 minutos entre o comando e o veredito, dependendo da execução. Cada agente sem tela carrega as regras globais da sua máquina (instruções, hooks, skills) e segue todas. Para tarefa pequena, o loop pode custar mais do que fazer na mão.

## O revisor não consegue rodar meus testes

Em somente leitura ele executa comando, mas não grava no disco. Se a sua suíte precisa escrever arquivo, cache ou banco local, ela pode falhar na revisão. Nos testes daqui o `npm test` com `node --test` rodou sem problema.

## Meu Codex tem um modo de sandbox padrão diferente

Os scripts passam `-s` explícito em toda chamada: `workspace-write` para implementar, `read-only` para revisar e auditar. Isso vale por cima da sua configuração.

## Modelo local

O caminho `local` chama o Codex com `--oss`. Está no script e passa no self-check, mas não foi rodado com um modelo de verdade.

## O implementador mexeu fora do escopo

O pacote diz o que pode e o que não pode ser alterado, e o revisor confere isso. Se acontecer, o parecer deve sair BLOCKED com o achado. Para limitar pela ferramenta também, aperte o `--allowedTools` no `loop.sh`.
