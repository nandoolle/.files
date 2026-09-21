#!/bin/sh
# Shared helpers for the AI mode actions.
#
# Every action runs claude -p in the background: a status-bar keypress must
# never block on a model call.
set -eu

NOTES_DIR="$HOME/.menunotes.tmux/notes"
MODEL_OPT="@ai_model"

model() { tmux show -gv "$MODEL_OPT" 2>/dev/null || true; }

# Run claude non-interactively with only the tools the action needs, while a
# background loop spins the status bar. status-interval is whole seconds only,
# so the loop advances @ai_frame and forces the redraw itself.
ask() {
  tools="$1"; shift
  m=$(model)
  out=$(mktemp)
  (
    set -- claude -p "$1" --allowed-tools "$tools"
    [ -n "$m" ] && set -- "$@" --model "$m"
    "$@" >"$out" 2>/dev/null
  ) &
  pid=$!

  f=0
  while kill -0 "$pid" 2>/dev/null; do
    tmux set -g @ai_frame "$f" 2>/dev/null || break
    tmux refresh-client -S 2>/dev/null || true
    f=$(( (f + 1) % 10 ))
    sleep 0.5
  done
  wait "$pid"
  rc=$?

  cat "$out"; rm -f "$out"
  return $rc
}

# Publishes both the task and the model actually in use, so the status bar
# never has to guess what the CLI default resolved to.
busy() {
  tmux set -g @ai_busy "$1"
  m=$(model); [ -n "$m" ] || m="default"
  tmux set -g @ai_running_model "$m"
}
idle() {
  tmux set -gu @ai_busy 2>/dev/null || true
  tmux set -gu @ai_running_model 2>/dev/null || true
  tmux set -gu @ai_frame 2>/dev/null || true
  tmux refresh-client -S 2>/dev/null || true
}
notify(){ tmux display-message "$1"; }
