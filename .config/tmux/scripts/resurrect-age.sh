#!/bin/bash
# tmux status segment: minutes since last tmux-resurrect save (via continuum).
last="$HOME/.local/share/tmux/resurrect/last"
[[ -e $last ]] || exit 0
age=$(( ($(date +%s) - $(stat -f %m "$last")) / 60 ))
printf "󰆓 %dm" "$age"
