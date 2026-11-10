#!/usr/bin/env bash
# loop.sh <tarefa> [teto]: implementa, revisa e corrige até fechar ou bater o teto de rodadas.
# Escalação por variável: REFINA e IMPLEMENTA aceitam claude, codex ou local.
# CORRIGE=<parecer> começa pela correção dos achados desse parecer (o da segurança, por exemplo).
set -euo pipefail
T="$1"; TETO="${2:-3}"
REFINA="${REFINA:-codex}"; IMPLEMENTA="${IMPLEMENTA:-claude}"
PACOTE="docs/handoff/$T.md"; LEDGER="docs/qa/$T-ledger.md"
LOCAL=(--oss --local-provider "${PROVEDOR_LOCAL:-ollama}" ${MODELO_LOCAL:+-m "$MODELO_LOCAL"})

for A in "$REFINA" "$IMPLEMENTA"; do
  case "$A" in claude|codex|local) ;; *) echo "Agente desconhecido: $A (use claude, codex ou local)"; exit 1 ;; esac
done
[ "$REFINA" != "$IMPLEMENTA" ] || { echo "Refinador e implementador precisam ser agentes diferentes."; exit 1; }
[ -f "$PACOTE" ] || { echo "Falta o pacote aprovado: $PACOTE"; exit 1; }
mkdir -p docs/qa

implementar() { # $1 = pedido
  case "$IMPLEMENTA" in
    claude) claude -p "$1" --permission-mode acceptEdits --permission-prompts none \
              --allowedTools "Read" "Edit" "Write" "Glob" "Grep" "Bash(npm test *)" < /dev/null ;;
    codex)  codex exec -s workspace-write "$1" < /dev/null ;;
    local)  codex exec "${LOCAL[@]}" -s workspace-write "$1" < /dev/null ;;
  esac
}

revisar() { # $1 = pedido, $2 = arquivo do parecer
  case "$REFINA" in
    claude) claude -p "$1" --permission-prompts none --disallowedTools "Edit" "Write" "NotebookEdit" \
              --allowedTools "Read" "Glob" "Grep" "Bash(npm test *)" "Bash(git status *)" "Bash(git diff *)" < /dev/null > "$2" ;;
    codex)  codex exec -s read-only -o "$2" "$1" < /dev/null ;;
    local)  codex exec "${LOCAL[@]}" -s read-only -o "$2" "$1" < /dev/null ;;
  esac
}

# Só vale a primeira linha do parecer, exata. Veredito citado no meio do texto não conta.
veredito() { awk 'NF{print; exit}' "$1" | tr -d '*\r' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }

echo "Escalação: refina $REFINA; implementa $IMPLEMENTA"
PEDIDO="Leia $PACOTE e implemente só o que ele pede. Antes de codar, confira se o pacote se contradiz; se sim, pare e explique."
if [ -n "${CORRIGE:-}" ]; then
  [ -f "$CORRIGE" ] || { echo "Não achei o parecer para corrigir: $CORRIGE"; exit 1; }
  PEDIDO="Leia $CORRIGE e corrija só os achados ABERTOS ou REABERTOS, dentro do escopo de $PACOTE."
fi
# Rodadas continuam a numeração dos pareceres que já existem, para não apagar histórico.
FEITAS="$(find docs/qa -name "$T-review-r*.md" | wc -l | tr -d " ")"
for N in $(seq 1 "$TETO"); do
  R=$((FEITAS + N))
  PARECER="docs/qa/$T-review-r$R.md"

  implementar "$PEDIDO Escreva o teste falhando antes do código. Registre a rodada $R em $LEDGER: arquivos alterados, comandos rodados, saída deles e o que ficou pendente. Não faça commit, push nem PR."

  revisar "Você é o revisor independente. Não edite nenhum arquivo. Leia $PACOTE, $LEDGER e as mudanças (git status, git diff e os arquivos novos). Rode os testes e tente quebrar a entrega com cenários que o implementador não cobriu. Na primeira linha da resposta escreva exatamente uma destas: VEREDITO: PASS, VEREDITO: PASS_WITH_RISK, VEREDITO: BLOCKED ou VEREDITO: NEEDS_HUMAN_QA. Depois liste cada achado com ID estável (CX-01, CX-02...), estado (ABERTO, FECHADO ou REABERTO), observado, esperado, impacto e reprodução. Feche com o que você conferiu de verdade e o que não deu para conferir." "$PARECER"

  VEREDITO="$(veredito "$PARECER")"
  echo "Rodada $R: ${VEREDITO:-sem veredito}"
  case "$VEREDITO" in
    "VEREDITO: BLOCKED")
      PEDIDO="Leia $PARECER e corrija só os achados ABERTOS ou REABERTOS, dentro do escopo de $PACOTE." ;;
    "VEREDITO: PASS"|"VEREDITO: PASS_WITH_RISK"|"VEREDITO: NEEDS_HUMAN_QA")
      echo "Fechou. Parecer em $PARECER. O aceite é seu."; exit 0 ;;
    *)
      echo "Parecer sem veredito válido: $PARECER"; exit 3 ;;
  esac
done
echo "Bateu o teto de $TETO rodadas ainda em BLOCKED. Agora é com você."; exit 2
