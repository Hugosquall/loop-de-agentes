# O fluxo

Dois agentes de modelos diferentes trabalham em loop. Um especifica e revisa, o outro implementa e corrige. Você escolhe quem faz o quê e entra em dois portões.

## As vagas

| Vaga | Faz | Entrega |
|---|---|---|
| Você | Define o problema, a prioridade e o limite. Escolhe a escalação, aprova o pacote e dá o ok final. | Direção e autorização |
| Refinador, especificando | Lê o repositório, faz perguntas, fecha plano e critérios de aceite | O pacote para implementar |
| Implementador | Contesta o pacote, implementa por partes, testa e registra | Código, testes e ledger |
| Refinador, revisando | Compara pacote, código e evidência. Reproduz a falha e confere a correção. | Parecer com veredito e achados |
| Auditor de segurança | Examina a versão que vai para o ar e separa falha confirmada de suspeita | Parecer de segurança |
| Maestro (opcional) | Pergunta a escalação, dispara os scripts e avisa | Nenhuma linha de código |

Ninguém aprova a própria entrega. O refinador escreve o pacote e revisa o código, mas quem contesta o pacote é o implementador e quem aprova é você.

## A escalação

Antes de cada tarefa você decide quem refina e quem implementa. Os scripts aceitam `claude`, `codex` e `local`.

- As duas vagas têm agentes diferentes. O script recusa o mesmo agente nas duas.
- O mais forte fica na revisão. Se o implementador é um modelo local menor, o refinador é o modelo em que você mais confia.
- A escalação fica escrita na primeira linha do pacote.

## Os sete passos

1. **Entender.** Você explica o problema e mostra referências. O refinador lê o que existe e pergunta até não sobrar dúvida de comportamento.
2. **Planejar.** Ele transforma o que você aprovou em etapas: o que entra, o que fica para depois, a ordem, os arquivos, os riscos e como comprovar cada resultado.
3. **Passar.** Tudo vira um arquivo, o pacote para implementar. **Portão 1:** você lê e aprova.
4. **Implementar.** O implementador confere o pacote, escreve o teste que falha, implementa e registra a rodada no ledger.
5. **Revisar.** O refinador lê o ledger e os arquivos, roda o que dá para rodar e procura o cenário que contradiz o "tá pronto".
6. **Corrigir e revalidar.** Achado aberto volta para o implementador. A correção volta para o refinador, que pode reabrir. Bateu o teto de rodadas, o loop para e chama você.
7. **Auditar e liberar.** Um auditor de segurança examina a versão que vai para o ar. Achado confirmado volta para o passo 6. Sem bloqueio, chega o **portão 2:** o ok final é seu.

Os passos 1 a 3 são conversa com o refinador (use [o prompt do especificador](../modelos/prompt-especificador.md)). Os passos 4 a 6 são o `loop.sh`. O passo 7 é o `seguranca.sh`.

## Os arquivos que os agentes trocam

Os agentes não conversam entre si. Um escreve um arquivo e o outro lê, tudo dentro do repositório.

```text
docs/handoff/<tarefa>.md         pacote para implementar (refinador escreve)
docs/qa/<tarefa>-ledger.md       relatório de execução, uma seção por rodada (implementador escreve)
docs/qa/<tarefa>-review-rN.md    parecer da rodada N (refinador escreve)
docs/qa/<tarefa>-seguranca.md    parecer de segurança (auditor escreve)
```

Modelos prontos: [pacote](../modelos/pacote.md), [ledger](../modelos/ledger.md) e [achado](../modelos/achado.md).

No ledger, o campo que mais evita mal-entendido é "o que cada evidência prova". Tela construída, lógica rodando com dado simulado e integração real são entregas diferentes.

## Os quatro vereditos

| Veredito | Significa |
|---|---|
| PASS | Os critérios do escopo revisado foram atendidos, com evidência |
| PASS_WITH_RISK | Passou, mas tem risco ou limitação registrada para você decidir |
| BLOCKED | Tem falha ou dependência que impede o aceite |
| NEEDS_HUMAN_QA | Falta uma pessoa validar a experiência |

O veredito tem que ser a primeira linha do parecer, exata. Veredito citado no meio do texto não conta.

Aprovar no loop e publicar são decisões separadas. Teste verde ou achado fechado não autoriza commit, PR, merge nem deploy.

## Regras de parada

- **Teto de rodadas.** O padrão é três. Bateu o teto ainda em BLOCKED, o loop para.
- **Parecer sem veredito válido para tudo.** O script não adivinha o que o revisor quis dizer.
- **Pacote contraditório para antes de codar.** O implementador explica a contradição e devolve.
- **Fora do escopo não entra na rodada.** Rodada de correção mexe só no achado aberto.
- **Nada de commit, push, PR, merge ou deploy dentro do loop.** O implementador nem recebe permissão para isso.
- **Teste não é apagado nem afrouxado para passar.** Conclusão corrigida vira rodada nova, e a anterior fica no histórico.

As duas primeiras estão no script. As outras estão nos pedidos e nas permissões de cada agente.
