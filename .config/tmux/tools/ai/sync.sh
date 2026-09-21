#!/bin/sh
# Re-check the noted tasks against the tracker and tick the finished ones.
#
# Commits the notes repo first, so a bad rewrite is always recoverable.
set -eu
. "$(dirname "$0")/lib.sh"

[ -d "$NOTES_DIR/.git" ] || { notify "sync: $NOTES_DIR nao e um repo git"; exit 1; }
busy "sync"

if ! git -C "$NOTES_DIR" diff --quiet HEAD 2>/dev/null || \
   [ -n "$(git -C "$NOTES_DIR" status --porcelain)" ]; then
  git -C "$NOTES_DIR" add -A
  git -C "$NOTES_DIR" commit -q -m "notes: snapshot before sync" || true
fi

tools="mcp__linear-server__list_issues,mcp__clickup__clickup_search,mcp__clickup__clickup_filter_tasks"

for src in linear clickup; do
  f="$NOTES_DIR/$src/notes.md"
  [ -f "$f" ] || continue

  prompt="Abaixo esta uma lista de tarefas em markdown.

Verifique no $src quais ja foram concluidas e devolva a MESMA lista,
marcando as concluidas com [x] e mantendo as demais com [ ].

Responda APENAS o markdown, sem preambulo e sem cercas de codigo.
Nao adicione, remova nem reescreva tarefas: so mude o [ ] para [x].

$(cat "$f")"

  if body=$(ask "$tools" "$prompt") && [ -n "$body" ]; then
    printf '%s\n' "$body" > "$f"
  fi
done

done_n=$(cat "$NOTES_DIR"/*/notes.md 2>/dev/null | grep -c '^- \[x\]' || echo 0)
notify "sync: $done_n concluidas"
idle
