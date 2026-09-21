# ai-mode.tmux -- one-key model calls from the status bar
#
# prefix+a enters AI; the next key picks an action and leaves the mode.
# Any unmapped key exits without doing anything.
#
#   l  summarise open Linear issues  -> notes/linear/notes.md
#   c  summarise the current ClickUp sprint (Technology board)
#   t  rename every window after the work in it (max 30 chars)
#   s  re-check the noted tasks and tick the finished ones
#   m  set the model for these calls (empty = the CLI default)
#
# Every action runs in the background: a keypress never blocks on the model.
#
# What leaves the machine: l/c/s send tracker data, t sends each pane's
# visible screen. Requires the `claude` CLI with the Linear and ClickUp MCPs.

set -g @ai_dir "~/.config/tmux/tools/ai"

bind a set -g key-table ai

bind -T ai Escape set -g key-table root
bind -T ai Any    set -g key-table root

bind -T ai l set -g key-table root \; run-shell -b "#{@ai_dir}/tasks.sh linear"
bind -T ai c set -g key-table root \; run-shell -b "#{@ai_dir}/tasks.sh clickup"
bind -T ai t set -g key-table root \; run-shell -b "#{@ai_dir}/rename-tabs.sh"
bind -T ai s set -g key-table root \; run-shell -b "#{@ai_dir}/sync.sh"
bind -T ai m set -g key-table root \; command-prompt -I "#{@ai_model}" \
  -p "model (vazio = padrao):" "set -g @ai_model '%%'"
