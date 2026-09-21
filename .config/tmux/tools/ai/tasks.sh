#!/bin/sh
# Summarise open work from Linear or ClickUp into the notes repo.
#
# Usage: tasks.sh linear|clickup
set -eu
. "$(dirname "$0")/lib.sh"

case "${1:-}" in
linear)
  tools="mcp__linear-server__list_issues,mcp__linear-server__list_projects"
  where="Linear"
  scope="issues abertas atribuidas a Fernando"
  ;;
clickup)
  tools="mcp__clickup__clickup_search,mcp__clickup__clickup_filter_tasks,mcp__clickup__clickup_get_workspace_hierarchy"
  where="ClickUp"
  scope="tarefas abertas no board Technology, apenas da sprint atual, e atribuidas a Fernando"
  ;;
*) exit 2 ;;
esac

out="$NOTES_DIR/$1/notes.md"
mkdir -p "$(dirname "$out")"
busy "$where"

prompt="Liste as $scope.

Responda APENAS com markdown, sem preambulo e sem cercas de codigo.
Formato exato, uma tarefa por linha:

## $where -- <data de hoje>

- [ ] <ID> <titulo em no maximo 60 caracteres>

Regras:
- no maximo 15 tarefas, as mais relevantes primeiro
- nunca invente IDs ou titulos; use o que a ferramenta retornar
- se nao houver nada, escreva apenas: (nada em aberto)"

if body=$(ask "$tools" "$prompt") && [ -n "$body" ]; then
  printf '%s\n' "$body" >"$out"
  notify "$where: $(grep -c '^- \[ \]' "$out" 2>/dev/null || echo 0) tarefas -> $1/notes.md"
else
  notify "$where: falhou"
fi
idle
