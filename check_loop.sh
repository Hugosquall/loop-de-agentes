#!/usr/bin/env bash
# check_loop.sh: confere a lógica do loop.sh e do seguranca.sh com claude, codex e npm falsos.
# Não chama modelo nem rede. Cobre desvio por veredito, teto, parecer inválido, escalação,
# retomada por parecer de correção e as duas camadas de segurança.
set -u
DIR="$(cd "$(dirname "$0")" && pwd)"; W="$(mktemp -d)"; trap 'rm -rf "$W"' EXIT; fail=0; total=0
mkdir "$W/bin"
cat > "$W/bin/claude" <<'STUB'
#!/usr/bin/env bash
# como revisor ou auditor devolve o próximo veredito no stdout; como implementador só registra a chamada
if printf '%s' "$*" | grep -q -e "revisor independente" -e "auditor de segurança"; then
  n=$(cat "$STUB_COUNT" 2>/dev/null); n=$(( ${n:-0} + 1 )); echo "$n" > "$STUB_COUNT"; sed -n "${n}p" "$STUB_VERDICTS" | tr '|' '\n'
else echo "claude $*" >> "$STUB_CALLS"; fi
STUB
cat > "$W/bin/codex" <<'STUB'
#!/usr/bin/env bash
# com -o é revisor ou auditor (grava o próximo veredito no arquivo); sem -o é implementador
all="$*"; out=""; while [ $# -gt 0 ]; do [ "$1" = "-o" ] && out="$2"; shift; done
if [ -n "$out" ]; then
  n=$(cat "$STUB_COUNT" 2>/dev/null); n=$(( ${n:-0} + 1 )); echo "$n" > "$STUB_COUNT"; sed -n "${n}p" "$STUB_VERDICTS" | tr '|' '\n' > "$out"
else echo "codex $all" >> "$STUB_CALLS"; fi
STUB
cat > "$W/bin/npm" <<'STUB'
#!/usr/bin/env bash
# npm audit falso: devolve o JSON que o caso pediu
cat "$STUB_NPM"; grep -q '"high":0,"critical":0' "$STUB_NPM"
STUB
chmod +x "$W/bin/"*
npmjson() { echo "{\"metadata\":{\"vulnerabilities\":{\"info\":0,\"low\":$1,\"moderate\":0,\"high\":$2,\"critical\":0,\"total\":0}}}"; }

run() { # script | nome | vereditos | args extras | exit esperado | chamadas ao revisor | env extra | trecho esperado | arquivo onde procurar | npm json
  local d; d="$(mktemp -d "$W/caso.XXXX")"; mkdir -p "$d/docs/handoff" "$d/docs/qa"; echo pacote > "$d/docs/handoff/t.md"
  printf '%b' "$3" > "$d/verdicts"; : > "$d/count"; : > "$d/calls"; echo "${10:-$(npmjson 0 0)}" > "$d/npm.json"
  [ -n "${PREP:-}" ] && ( cd "$d" && eval "$PREP" )
  ( cd "$d" && env PATH="$W/bin:$PATH" STUB_VERDICTS="$d/verdicts" STUB_COUNT="$d/count" STUB_CALLS="$d/calls" STUB_NPM="$d/npm.json" ${7:-} bash "$DIR/$1" t $4 >"$d/out" 2>&1 ); local rc=$?
  local n; n="$(cat "$d/count")"; n="${n:-0}"; local okc=1; total=$((total+1))
  [ -n "${8:-}" ] && { grep -q -- "$8" "$d/${9:-calls}" || okc=0; }
  if [ "$rc" = "$5" ] && [ "$n" = "$6" ] && [ $okc = 1 ]; then echo "ok   $2"; else echo "FAIL $2: exit $rc/$5, revisor $n/$6, trecho ok=$okc"; cat "$d/out" "$d/calls"; fail=1; fi
}

echo "loop.sh"
run loop.sh "passa de primeira"            'VEREDITO: PASS\n'                                          3 0 1 "" "claude -p"
run loop.sh "bloqueia e depois passa"      'VEREDITO: BLOCKED\nVEREDITO: PASS_WITH_RISK\n'             3 0 2
run loop.sh "veredito em negrito"          '**VEREDITO: BLOCKED**\n**VEREDITO: PASS**\n'               3 0 2
run loop.sh "bate o teto"                  'VEREDITO: BLOCKED\nVEREDITO: BLOCKED\nVEREDITO: BLOCKED\n' 2 2 2
run loop.sh "precisa de humano"            'VEREDITO: NEEDS_HUMAN_QA\n'                                3 0 1
run loop.sh "parecer sem veredito"         'acho que ficou bom\n'                                      3 3 1
run loop.sh "veredito inventado"           'VEREDITO: APPROVED\n'                                      3 3 1
run loop.sh "veredito citado antes não vale" 'Evidência: VEREDITO: PASS|VEREDITO: BLOCKED\n'              3 3 1
run loop.sh "veredito com sobra não vale"   'VEREDITO: PASS123\n'                                       3 3 1
run loop.sh "linha em branco antes vale"    '|VEREDITO: PASS|resto do parecer\n'                        3 0 1
run loop.sh "invertido: claude revisa"     'VEREDITO: BLOCKED\nVEREDITO: PASS\n'                       3 0 2 "REFINA=claude IMPLEMENTA=codex" "codex exec -s workspace-write"
run loop.sh "local implementa"             'VEREDITO: PASS\n'                                          3 0 1 "REFINA=claude IMPLEMENTA=local MODELO_LOCAL=qwen" "codex exec --oss --local-provider ollama -m qwen -s workspace-write"
run loop.sh "local no lmstudio"            'VEREDITO: PASS\n'                                          3 0 1 "REFINA=codex IMPLEMENTA=local PROVEDOR_LOCAL=lmstudio" "codex exec --oss --local-provider lmstudio -s workspace-write"
run loop.sh "mesmo agente nas duas vagas"  'VEREDITO: PASS\n'                                          3 1 0 "REFINA=claude IMPLEMENTA=claude"
run loop.sh "agente desconhecido"          'VEREDITO: PASS\n'                                          3 1 0 "IMPLEMENTA=gemini"
PREP='echo "VEREDITO: BLOCKED" > docs/qa/t-seguranca.md' \
run loop.sh "corrige a partir de um parecer" 'VEREDITO: PASS\n'                                        3 0 1 "CORRIGE=docs/qa/t-seguranca.md" "Leia docs/qa/t-seguranca.md e corrija"
run loop.sh "parecer de correção inexistente" 'VEREDITO: PASS\n'                                       3 1 0 "CORRIGE=docs/qa/nao-existe.md"
PREP='echo antigo > docs/qa/t-review-r1.md; echo antigo > docs/qa/t-review-r2.md' \
run loop.sh "não sobrescreve parecer antigo" 'VEREDITO: PASS\n'                                        3 0 1 "" "Parecer em docs/qa/t-review-r3.md" out
d="$(mktemp -d "$W/caso.XXXX")"; ( cd "$d" && bash "$DIR/loop.sh" nada >/dev/null 2>&1 ); rc=$?; total=$((total+1)); [ "$rc" = 1 ] && echo "ok   sem pacote" || { echo "FAIL sem pacote (exit $rc)"; fail=1; }

echo "seguranca.sh"
run seguranca.sh "dependência grave bloqueia sem chamar o auditor" 'VEREDITO: PASS\n' "" 2 0 "" "VEREDITO: BLOCKED" docs/qa/t-seguranca.md "$(npmjson 0 2)"
run seguranca.sh "tudo limpo passa"                      'VEREDITO: PASS\n'           "" 0 1 "" "^VEREDITO: PASS$" docs/qa/t-seguranca.md
run seguranca.sh "dependência leve vira risco"           'VEREDITO: PASS\n'           "" 0 1 "" "^VEREDITO: PASS_WITH_RISK$" docs/qa/t-seguranca.md "$(npmjson 3 0)"
run seguranca.sh "achado confirmado bloqueia"            'VEREDITO: BLOCKED\n'        "" 2 1 "" "CORRIGE=docs/qa/t-seguranca.md ./loop.sh t" out
run seguranca.sh "só suspeita passa com risco"           'VEREDITO: PASS_WITH_RISK\n' "" 0 1
run seguranca.sh "veredito citado antes não vale"       'Citação: VEREDITO: PASS|VEREDITO: BLOCKED\n' "" 3 1
run seguranca.sh "auditor sem veredito"                  'parece seguro\n'            "" 3 1
run seguranca.sh "npm audit com erro para tudo"          'VEREDITO: PASS\n'           "" 3 0 "" "Camada 0 não rodou" out '{"error":{"code":"ENOLOCK"}}'
run seguranca.sh "claude audita, codex implementou"      'VEREDITO: PASS\n'           "" 0 1 "AUDITA=claude IMPLEMENTA=codex" "^VEREDITO: PASS$" docs/qa/t-seguranca.md
run seguranca.sh "auditor igual ao implementador"        'VEREDITO: PASS\n'           "" 1 0 "AUDITA=claude IMPLEMENTA=claude"
run seguranca.sh "auditor desconhecido"                  'VEREDITO: PASS\n'           "" 1 0 "AUDITA=gemini"
[ $fail = 0 ] && echo "$total casos ok"; exit $fail
