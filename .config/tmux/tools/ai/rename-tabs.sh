#!/bin/sh
# Rename each window after the work happening in it.
#
# Sends command, path, pane title and the visible screen of every window, so
# whatever is on screen goes to the model. Names are truncated here, not by
# the prompt, and a window is left alone if the reply does not parse.
set -eu
. "$(dirname "$0")/lib.sh"

MAX=30
busy "tabs"

ctx=$(tmux list-windows -F '#{window_index}|#{pane_current_command}|#{pane_current_path}|#{pane_title}' |
      while IFS='|' read -r i cmd path title; do
        printf '=== janela %s\ncomando: %s\ndiretorio: %s\ntitulo: %s\ntela:\n%s\n\n' \
          "$i" "$cmd" "$path" "$title" \
          "$(tmux capture-pane -p -t "$i" -S -12 2>/dev/null | sed 's/^/  /' | tail -12)"
      done)

prompt="Abaixo esta o estado de cada janela do tmux.

Para cada uma, escolha um nome curto que descreva o TRABALHO em andamento.

Responda APENAS linhas no formato:
<numero da janela>=<nome>

Regras:
- no maximo $MAX caracteres por nome
- minusculas, palavras separadas por hifen
- nada de aspas, espacos ou barras
- uma linha por janela, sem preambulo e sem cercas de codigo
- se nao der para dizer o que a janela faz, repita o nome do comando

$ctx"

reply=$(ask "" "$prompt") || reply=""
[ -n "$reply" ] || { notify "tabs: falhou"; idle; exit 1; }

n=0
printf '%s\n' "$reply" | while IFS='=' read -r idx name; do
  case "$idx" in ''|*[!0-9]*) continue ;; esac
  # sanitise here: the model is asked for this shape but never trusted to obey
  name=$(printf '%s' "$name" | tr -cd 'a-zA-Z0-9._-' | cut -c1-"$MAX")
  [ -n "$name" ] || continue
  tmux rename-window -t ":=$idx" "$name" 2>/dev/null && n=$((n + 1))
done

notify "tabs renomeadas"
idle
