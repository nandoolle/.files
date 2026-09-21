# move-mode.tmux -- modal navigation and rearrangement for tmux
#
# prefix+m enters MOVE; from there W, P and R open the submodes.
# Escape steps back one level, to root from MOVE. Any other unmapped key
# leaves the modes entirely, so a stray keystroke cannot run a normal
# binding while the bar still reads MOVE. The active table shows up in
# the status bar via #{client_key_table}.
#
#   MOVE        hjkl panes | HL windows | JK sessions | W/P/R submodes (either case)
#   MOVE-PANE   hk/jl reorder | HL to prev/next window | J to session | K break out
#   MOVE-WINDOW hl reorder | J to another session | K to a new session
#   RESIZE      hjkl one cell per press
#
# Requires: prefix+m free. No dependency on the rest of the config.

# The key-table option is what makes a mode sticky AND visible: switch-client -T
# only lasts for the next key and never reaches #{client_key_table}.
bind m set -g key-table move

bind -T move Escape set -g key-table root
bind -T move Any set -g key-table root
bind -T move h select-pane -L
bind -T move j select-pane -D
bind -T move k select-pane -U
bind -T move l select-pane -R
bind -T move H previous-window
bind -T move L next-window
bind -T move J switch-client -n
bind -T move K switch-client -p
bind -T move P set -g key-table move-pane
bind -T move p set -g key-table move-pane
bind -T move W set -g key-table move-window
bind -T move w set -g key-table move-window
bind -T move R set -g key-table move-resize
bind -T move r set -g key-table move-resize

# MOVE-PANE: rearrange the current pane instead of moving the cursor.
# tmux has no directional pane targets, so h/k and j/l walk the pane order.
bind -T move-pane Escape set -g key-table move
bind -T move-pane Any set -g key-table root
bind -T move-pane h swap-pane -U
bind -T move-pane j swap-pane -D
bind -T move-pane k swap-pane -U
bind -T move-pane l swap-pane -D
bind -T move-pane H join-pane -t :-
bind -T move-pane L join-pane -t :+
bind -T move-pane J choose-tree -Zs "join-pane -t '%%'"
bind -T move-pane K break-pane

# MOVE-WINDOW: reorder the current window, or move it to another session.
# swap-window leaves the focus on the position, not on the window, so each
# bind re-selects the window it just moved -- otherwise a second press would
# move a different window.
bind -T move-window Escape set -g key-table move
bind -T move-window Any set -g key-table root
bind -T move-window h swap-window -t :-1 \; select-window -t :-1
bind -T move-window l swap-window -t :+1 \; select-window -t :+1
bind -T move-window J choose-tree -Zs "move-window -t '%%'"
bind -T move-window K command-prompt -p "move to new session:" "new-session -d -s '%%' \; move-window -t '%%'"

# RESIZE: one cell per key press.
bind -T move-resize Escape set -g key-table move
bind -T move-resize Any set -g key-table root
bind -T move-resize h resize-pane -L 1
bind -T move-resize j resize-pane -D 1
bind -T move-resize k resize-pane -U 1
bind -T move-resize l resize-pane -R 1

