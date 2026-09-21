#!/bin/sh
# Resize the window-name field so the tabs fill the status bar.
#
# tmux's #{pN:} padding takes a literal number, never an expression, so the
# width cannot be computed at render time. The config ships a #{p@W:}
# placeholder; this stashes that template on first run and rewrites the two
# options from it whenever the geometry changes.
#
# Runs from hooks only (window-linked/unlinked, client-resized), never per tick.
set -eu

client=$(tmux display -p '#{client_width}' 2>/dev/null) || exit 0
count=$(tmux display -p '#{session_windows}' 2>/dev/null) || exit 0
case "$count" in ''|*[!0-9]*) exit 0 ;; esac
[ "$count" -gt 0 ] || exit 0

plain() { tmux display -p "#{T:$1}" 2>/dev/null | sed 's/#\[[^]]*\]//g'; }

# Display columns, not characters: the Nerd Font glyphs are double-width, and
# wc -m counts them as one, which is what made the bar overflow.
cols() {
  printf '%s' "$1" | python3 -c '
import sys, unicodedata
t = sys.stdin.read()
n = 0
for c in t:
    if unicodedata.combining(c):
        continue
    wide = (unicodedata.east_asian_width(c) in "WF"
            or 0xE000 <= ord(c) < 0xF900 or 0xF0000 <= ord(c) < 0xF1000)
    n += 2 if wide else 1
print(n)'
}

reserved=$(( $(cols "$(plain status-left)") + $(cols "$(plain status-right)") ))
# Measure the real per-tab overhead instead of assuming it: the glyphs are
# double-width, and guessing it low overflows the bar, which shifts every
# click range and breaks tab clicks.
# Measured once from the pristine template: reading it back from the live
# option would feed the previous run's padding into the next calculation.
overhead=$(tmux show -gv @tab_overhead 2>/dev/null || true)
if [ -z "$overhead" ]; then
  # Render the template with a known-width name and subtract it. Measuring
  # against the live window would fold that window's name into the constant.
  probe=$(tmux display -p "#{T:#{s/#{p@W:window_name}/XXXXXXXXXX/:@tmpl_windowstatusformat}}" \
          2>/dev/null | sed 's/#\[[^]]*\]//g')
  overhead=$(( $(cols "$probe") - 10 ))
  [ "$overhead" -lt 8 ] && overhead=17
  tmux set -g @tab_overhead "$overhead"
fi

# -1 per tab for the separator drawn between them
width=$(( (client - reserved - count) / count - overhead ))
[ "$width" -lt 6 ] && width=6

for opt in window-status-format window-status-current-format; do
  stash="@tmpl_$(printf '%s' "$opt" | tr -d -)"
  tmpl=$(tmux show -gv "$stash" 2>/dev/null || true)
  if [ -z "$tmpl" ]; then
    tmpl=$(tmux show -gv "$opt")
    case "$tmpl" in *'p@W:'*) tmux set -g "$stash" "$tmpl" ;; *) continue ;; esac
  fi
  tmux set -g "$opt" "$(printf '%s' "$tmpl" | sed "s/p@W:/p$width:/g")"
done
