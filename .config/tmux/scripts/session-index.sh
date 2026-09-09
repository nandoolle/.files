#!/bin/sh
# tmux has no session base-index; rename default numeric names to start at 1.
s="$1"
case "$s" in ''|*[!0-9]*) exit 0 ;; esac
n=1
while tmux has-session -t "=$n" 2>/dev/null; do n=$((n + 1)); done
[ "$n" = "$s" ] || tmux rename-session -t "=$s" "$n"
