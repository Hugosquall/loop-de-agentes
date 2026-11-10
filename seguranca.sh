#!/usr/bin/env bash
# seguranca.sh <tarefa>: etapa de segurança, depois que o loop fechou e antes do ok final.
# Camada 0: dependências de produção. Camada 1: auditor de código em somente leitura.
# AUDITA e IMPLEMENTA aceitam claude, codex ou local, e precisam ser diferentes.
set -euo pipefail
T="$1"
AUDITA="${AUDITA:-codex}"; IMPLEMENTA="${IMPLEMENTA:-claude}"
PACOTE="docs/handoff/$T.md"; PARECER="docs/qa/$T-seguranca.md"
LOCAL=(--oss --local-provider "${PROVEDOR_LOCAL:-ollama}" ${MODELO_LOCAL:+-m "$MODELO_LOCAL"})

case "$AUDITA" in claude|codex|local) ;; *) echo "Agente desconhecido: $AUDITA (use claude, codex ou local)"; exit 1 ;; esac
[ "$AUDITA" != "$IMPLEMENTA" ] || { echo "O auditor não pode ser o implementador."; exit 1; }
[ -f "$PACOTE" ] || { echo "Falta o pacote: $PACOTE"; exit 1; }
mkdir -p docs/qa; TMP="$(mktemp)"; trap 'rm -f "$TMP"' EXIT

# Camada 0: alta ou crítica bloqueia; moderada e baixa entram como risco.
read -r GRAVES LEVES <<< "$(npm audit --omit=dev --json 2>/dev/null | node -e '
  let s=""; process.stdin.on("data", d => s += d).on("end", () => {
    try { const v = JSON.parse(s).metadata.vulnerabilities; console.log(v.critical + v.high, v.moderate + v.low) }
    catch { console.log("erro erro") } })')"
[ "$GRAVES" != "erro" ] || { echo "Camada 0 não rodou: npm audit falhou (falta package-lock.json?)."; exit 3; }
DEPS="Dependências de produção (npm audit --omit=dev): $GRAVES altas ou críticas, $LEVES moderadas ou baixas."
echo "Camada 0: $DEPS"
if [ "$GRAVES" -gt 0 ]; then
  printf 'VEREDITO: BLOCKED\n\n## Camada 0\n\nSEC-00 [ABERTO] %s\nReprodução: npm audit --omit=dev\nAtualizar dependência é decisão sua e não entra no loop.\n' "$DEPS" > "$PARECER"
  echo "VEREDITO: BLOCKED. Parecer em $PARECER."; exit 2
fi

# Camada 1: só roda se a camada 0 não bloqueou.
PEDIDO="Você é o auditor de segurança. Não edite nenhum arquivo. Leia $PACOTE e o código que vai para o ar (git status, git diff, os arquivos novos e quem chama o que mudou). Procure o que um atacante consegue fazer: entrada não validada, falha de autorização, segredo exposto, injeção, negação de serviço, dado de outro usuário. Tente reproduzir cada suspeita com um teste ou comando. Na primeira linha da resposta escreva exatamente uma destas: VEREDITO: BLOCKED se houver ao menos um achado CONFIRMADO, VEREDITO: PASS_WITH_RISK se houver só SUSPEITA, VEREDITO: PASS se não houver achado, ou VEREDITO: NEEDS_HUMAN_QA se a conclusão depender de ambiente que você não alcança. Depois liste cada achado com ID estável (SEC-01, SEC-02...), classificação (CONFIRMADO, com a reprodução que você observou; SUSPEITA, com o fato que falta; ou REJEITADO), estado (ABERTO, FECHADO ou REABERTO), atacante, impacto e reprodução. Feche com o que você conferiu de verdade e o que não deu para conferir."
case "$AUDITA" in
  claude) claude -p "$PEDIDO" --permission-prompts none --disallowedTools "Edit" "Write" "NotebookEdit" \
            --allowedTools "Read" "Glob" "Grep" "Bash(npm test *)" "Bash(git status *)" "Bash(git diff *)" < /dev/null > "$TMP" ;;
  codex)  codex exec -s read-only -o "$TMP" "$PEDIDO" < /dev/null ;;
  local)  codex exec "${LOCAL[@]}" -s read-only -o "$TMP" "$PEDIDO" < /dev/null ;;
esac

# Só vale a primeira linha do parecer, exata. Veredito citado no meio do texto não conta.
veredito() { awk 'NF{print; exit}' "$1" | tr -d '*\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }
VEREDITO="$(veredito "$TMP")"
[ "$VEREDITO" = "VEREDITO: PASS" ] && [ "$LEVES" -gt 0 ] && VEREDITO="VEREDITO: PASS_WITH_RISK"
case "$VEREDITO" in
  "VEREDITO: BLOCKED") SAIDA=2 ;;
  "VEREDITO: PASS"|"VEREDITO: PASS_WITH_RISK"|"VEREDITO: NEEDS_HUMAN_QA") SAIDA=0 ;;
  *) cp "$TMP" "$PARECER"; echo "Parecer sem veredito válido: $PARECER"; exit 3 ;;
esac
{ echo "$VEREDITO"; printf '\n## Camada 0\n\n%s\n\n## Camada 1\n\n' "$DEPS"; cat "$TMP"; } > "$PARECER"
echo "$VEREDITO. Parecer em $PARECER."
[ "$SAIDA" = 0 ] || echo "Para corrigir pelo loop: CORRIGE=$PARECER ./loop.sh $T"
exit "$SAIDA"
