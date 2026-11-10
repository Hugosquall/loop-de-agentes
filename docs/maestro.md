# O maestro

O maestro é opcional. É um bot que pergunta a escalação, dispara os scripts no seu computador e avisa quando o fluxo chega num portão.

**Estado: desenhado, ainda sem rodada completa.** A instrução abaixo não foi testada de ponta a ponta com nenhum bot.

## O que ele faz e o que não faz

| Faz | Não faz |
|---|---|
| Pergunta quem refina e quem implementa | Não escolhe a escalação por você |
| Confere se o pacote existe e dispara o `loop.sh` | Não escreve nem revisa código |
| Lê o último parecer e manda veredito e achados abertos | Não decide veredito |
| Pergunta se roda a segurança e quem audita | Não dispara pentest sozinho |
| Avisa quando o script para no teto ou num parecer inválido | Não faz commit, push, PR, merge nem deploy |

A regra do loop fica no script, que é burro e previsível. Um terceiro modelo decidindo o próximo passo seria mais uma coisa para errar.

## A instrução

Está em [modelos/prompt-maestro.md](../modelos/prompt-maestro.md). Troque `[caminho]` pelo caminho do seu repositório e cole como instrução do bot.

## O que o bot precisa ter

- Executar comando no seu computador, dentro da pasta do repositório.
- Ler arquivos em `docs/`.
- Mandar mensagem ou notificação para você.

## Cuidados

- Bot com permissão de rodar comando no seu computador roda qualquer comando. Deixe a aprovação por comando ligada até confiar.
- Nunca dê ao bot acesso a `.env`, chave ou senha.
- Se o bot roda na nuvem, o que ele lê do seu repositório sai da sua máquina.
- Comece rodando os scripts você mesmo. Só ponha um bot no meio depois que o loop funcionar na sua mão.
