Quero montar um loop de desenvolvimento com dois agentes de modelos diferentes:
1. Antes de cada tarefa eu escolho a escalação: quem refina e quem implementa.
2. O refinador me entrevista, fecha plano e critérios de aceite e escreve um pacote para implementar.
3. Eu aprovo o pacote.
4. O implementador trabalha em ambiente isolado, com teste antes do código, e registra cada rodada num relatório de execução.
5. O refinador revisa em modo somente leitura, tenta quebrar a entrega e responde com um veredito: PASS, PASS_WITH_RISK, BLOCKED ou NEEDS_HUMAN_QA.
6. BLOCKED volta para o implementador com achados numerados, até fechar ou bater um teto de rodadas.
7. Antes do ok final, um auditor de segurança examina a versão que vai para o ar: dependências, código e, quando o risco pede, pentest em ambiente meu.
8. Eu aceito ou devolvo. Commit, PR, merge e deploy ficam fora do loop.

Meu projeto: [linguagem, tamanho, comando de teste, ferramentas que já uso]
Meus agentes: [quais modelos ou assinaturas eu tenho, e se rodo algum modelo local]

Me devolva:
- o modelo de pacote, de relatório de execução e de achado, adaptados ao meu projeto;
- o prompt de cada papel;
- as regras de parada e os gatilhos de risco que pedem pentest;
- a primeira tarefa pequena para eu rodar o loop na mão antes de automatizar.
Use as ferramentas que eu já tenho. Não sugira instalar nada que eu não pedi.
