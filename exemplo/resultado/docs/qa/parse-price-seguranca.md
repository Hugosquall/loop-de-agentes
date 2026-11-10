VEREDITO: PASS_WITH_RISK

## Camada 0

Dependências de produção (npm audit --omit=dev): 0 altas ou críticas, 0 moderadas ou baixas.

## Camada 1

VEREDITO: PASS_WITH_RISK

Nenhuma vulnerabilidade explorável foi confirmada no pacote local. Há uma suspeita de disponibilidade condicionada à integração.

**SEC-01 — SUSPEITA — ABERTO — Entrada sem limite de tamanho**

- **Local:** `src/parse-price.js:18`. A conversão para `BigInt` ocorre antes da rejeição por limite numérico.
- **Atacante:** alguém que consiga fornecer strings grandes à função.
- **Impacto:** possível bloqueio da execução e consumo elevado de memória.
- **Observado:** 16 milhões de dígitos levaram **1.367 ms** até `RangeError`; um timer ficou atrasado por **1.370 ms**. O processo chegou a aproximadamente **142 MiB de RSS**.
- **Fato faltante:** um chamador de produção que aceite esse volume de entrada não confiável. Neste repositório, apenas os testes chamam a função; portanto, **não confirmei DoS remoto**.
- **Reprodução executada:**

```sh
rtk proxy node --input-type=module -e '
import {parsePrice} from "./src/parse-price.js";
const input="9".repeat(16000000);
const start=performance.now();
setTimeout(()=>console.log("timer_ms",performance.now()-start),0);
try { parsePrice(input); }
catch(e) { console.log(e.name,"parse_ms",performance.now()-start); }
'
```

Recomendação: definir um limite de entrada antes de integrar a função a uma superfície exposta.

**SEC-02 — REJEITADO — FECHADO — Injeção pela entrada ou mensagem de erro**

- **Local:** `src/parse-price.js:11`.
- **Atacante:** quem controla o texto recebido.
- **Impacto investigado:** execução de código, comandos ou HTML.
- **Reprodução observada:** `10;process.exit(88)`, `10 OR 1=1` e `<script>probe</script>` lançaram `TypeError`. Objetos com `toString` foram rejeitados sem executar a conversão.
- A mensagem preserva HTML e quebras de linha, mas não existe destino que interprete esse conteúdo. Não foi demonstrada injeção.

**SEC-03 — REJEITADO — FECHADO — Manipulação de centavos por overflow**

- **Atacante:** quem fornece preços extremos.
- **Impacto investigado:** corrupção silenciosa do valor, anteriormente registrada como CX-01.
- **Reprodução observada:** `90071992547409,91` retornou exatamente `9007199254740991`; valores terminados em `,92`, `,93` e `"9".repeat(309)` lançaram `RangeError`.
- A revisão independente também passou em **5.001 verificações de precisão**.

**Conferido de verdade:**

- Handoff, cinco arquivos novos, manifests, implementação, testes e todos os chamadores encontrados.
- `git status`, diff contra `HEAD`, diff staged e diffs dos novos arquivos de código.
- `rtk proxy npm test`: **8/8 passaram**, no Node `v22.23.2`.
- Ausência de segredos identificáveis, rede, autenticação, persistência e acesso a dados de terceiros no código auditado.
- Inventário e hashes dos oito arquivos iguais antes e depois; nenhum arquivo alterado.

Não conferi produção nem controles externos de entrada, pois não estão presentes neste pacote local.  
Risco residual: SEC-01 depende de como a função será exposta a entradas não confiáveis.