# A etapa de segurança

A revisão confere se a entrega faz o que o pacote pede. A segurança faz outra pergunta: o que alguém mal-intencionado consegue fazer com ela. São ferramentas diferentes e mais caras, então essa etapa roda uma vez, na versão que vai para o ar, e não a cada rodada do loop.

## As camadas

| Camada | O que roda | Quando | Está no script? |
|---|---|---|---|
| 0. Dependências | `npm audit --omit=dev` | Sempre | Sim |
| 1. Código | Um auditor em somente leitura | Toda entrega que vai para produção | Sim |
| 2. Pentest | Uma ferramenta de pentest contra o app rodando em laboratório ou homologação | Quando o risco pede | Não |

A camada barata vem primeiro. Se a camada 0 bloqueia, o script para ali e não gasta modelo.

## Como o seguranca.sh decide

- **Dependência com falha alta ou crítica bloqueia.** Atualizar dependência pode quebrar coisa, então essa correção é sua e não entra no loop.
- **Falha moderada ou baixa não bloqueia.** Vira risco e o veredito sai PASS_WITH_RISK.
- **O auditor só lê.** Ele tenta reproduzir cada suspeita e classifica cada achado como CONFIRMADO, SUSPEITA ou REJEITADO.
- **Achado confirmado sai BLOCKED**, com ID `SEC-01`, e o script mostra o comando para devolver ao implementador pelo mesmo loop.
- **Só suspeita sai PASS_WITH_RISK.** A decisão é sua.

## Quando o risco pede pentest

Quando a entrega mexe em:

- login ou permissão;
- dinheiro;
- upload ou entrada vinda de fora;
- endpoint novo exposto;
- dado de mais de um cliente.

## Regras

- **O auditor não é o implementador.**
- **Pentest só em ambiente seu.** Laboratório ou homologação, com alvo e escopo escritos antes. Nunca em produção e nunca em sistema de terceiro.
- **Relatório de pentest fica fora do repositório.** Ele pode trazer credencial e prova de exploração.
- **Em repositório público, não suba o parecer de segurança antes de corrigir o que ele aponta.**
- **Auditoria feita por IA aponta suspeita.** Reproduza antes de corrigir e antes de confiar.

## Para ir mais fundo

No script, a camada 1 é um auditor só. Duas opções mais pesadas, rodadas à parte:

- [cloudflare/security-audit-skill](https://github.com/cloudflare/security-audit-skill): auditoria de código com vários agentes, em que um tenta derrubar o achado do outro.
- [vxcontrol/pentagi](https://github.com/vxcontrol/pentagi): sistema aberto de agentes que planeja e executa pentest dentro de containers. Tem API, então dá para um bot disparar.

Nenhuma das duas foi integrada nem testada com estes scripts.
