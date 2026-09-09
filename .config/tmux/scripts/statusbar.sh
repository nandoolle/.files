#!/bin/bash
# Two-line status bar at the top: [0] theme bar, [1] vitals.
#
# Runs AFTER TPM on every load and reload (the theme resets status-left/right).
# Each step is idempotent, so a reload is a no-op.

# --- status-left: resurrect save age, right before the session name ---
left="$(tmux show -gv status-left)"
if [[ $left != *"resurrect-age.sh"* ]]; then
  tmux set -g status-left "${left/\#S/#(~/.config/tmux/scripts/resurrect-age.sh)  #S}"
fi

# --- two-line bar ---
tmux set -g status 2
# Raised panel in two Tokyo Night surface tones, both above the Night terminal
# bg (#1a1b26): theme line in Storm bg_dark, vitals line in Storm bg. The theme's
# segments use bg=default, which resolves to status-style inside the bar.
bar_top="#1f2335"
bar_bottom="#24283b"
tmux set -g status-style "bg=$bar_top"
# Once any status-format[N] is set, unset indexes read as empty instead of the
# built-in default, so [0] has to hold the default explicitly (read from a
# throwaway server, so it tracks the running tmux version).
if [[ -z $(tmux show -gv 'status-format[0]') ]]; then
  default_bar="$(tmux -L statusbar-probe -f /dev/null start-server \; show -gv 'status-format[0]')"
  [[ -n $default_bar ]] && tmux set -g 'status-format[0]' "$default_bar"
fi
tmux set -g 'status-format[1]' "#[fill=$bar_bottom,bg=$bar_bottom]#[align=left] #{vitals_llm}#[align=right]#{vitals_system} "

# --- interpolate the #{vitals_*} placeholders just written above ---
# vitals.tmux already ran earlier (before status-format[1] existed), so re-run
# its entry point now to fill in this script's own placeholders.
plugin_path="${TMUX_PLUGIN_MANAGER_PATH:-$HOME/.tmux/plugins}"
vitals_tmux="${plugin_path%/}/tmux-vitals/vitals.tmux"
[[ -x $vitals_tmux ]] && "$vitals_tmux"
