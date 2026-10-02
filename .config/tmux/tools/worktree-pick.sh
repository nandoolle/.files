#!/bin/sh
# Pick a worktree with tv (channel "worktrees") and open it as a window of the
# current session, or jump to the window if it is already open.
dir=$(tv worktrees) || exit 0
[ -d "$dir" ] || exit 0
name=$(basename "$dir")
tmux select-window -t ":=$name" 2>/dev/null || tmux new-window -c "$dir" -n "$name"
