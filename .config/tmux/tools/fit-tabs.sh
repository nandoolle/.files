#!/bin/sh
# Resize the window-name field so the tabs fill the status bar of each session.
#
# #{pN:} takes a literal number, so the global format keeps a @W placeholder and
# this writes the resolved copy onto each window of the session given in $1, or
# of every session without one. Runs from hooks only, never per tick.
set -eu

target=${1:-}

# Hooks fire in bursts (a drag-resize, several kills) and run in parallel, so an
# older run could finish last with stale geometry. Serialize them, and skip a
# request when a newer one for the same session is already queued behind it.
if [ -n "$target" ]; then
  tmux set -t "$target" @tab_fit_req "$$" 2>/dev/null || exit 0
fi
tmux wait-for -L fit-tabs
trap 'tmux wait-for -U fit-tabs' EXIT
trap 'exit 1' HUP INT TERM
if [ -n "$target" ]; then
  [ "$(tmux show -t "$target" -v @tab_fit_req 2>/dev/null)" = "$$" ] || exit 0
fi

tmpl=$(tmux show -gv window-status-format)
tmpl_cur=$(tmux show -gv window-status-current-format)
case "$tmpl$tmpl_cur" in *'@W:'*) ;; *) exit 0 ;; esac

# Prints the name width that fills the bar, from status-left, the right side
# and one "active<TAB>format<TAB>current-format" row per window, rendered with
# a 10-column name. Display columns, not characters: Nerd Font glyphs are
# double-width, and counting them as one is what made the bar overflow.
measure='
import re, sys, unicodedata
def cols(t):
    n = 0
    for c in re.sub(r"#\[[^]]*\]", "", t):
        if unicodedata.combining(c):
            continue
        wide = (unicodedata.east_asian_width(c) in "WF"
                or 0xE000 <= ord(c) < 0xF900 or 0xF0000 <= ord(c) < 0x110000)
        n += 2 if wide else 1
    return n
client = int(sys.argv[1])
left, right, *rows = sys.stdin.read().split("\n")
rows = [r.split("\t") for r in rows if r]
# per tab, not a constant: a two-digit index widens its tab by one glyph
overhead = sum(cols(cur if active == "1" else fmt) - 10 for active, fmt, cur in rows)
# -1 per tab for the separator between them and the bar closing the last one
width = (client - cols(left) - cols(right) - len(rows) - overhead) // len(rows)
print(max(width, 6))'

fit() {
  s=$1
  status=$(tmux display -p -t "$s" '#{status}' 2>/dev/null) || return 0
  # One format serves every client on the session; the narrowest must not overflow.
  client=$(tmux list-clients -t "$s" -F '#{client_width}' 2>/dev/null | sort -n | head -1)
  if [ "$status" = off ] || [ -z "$client" ]; then
    tmux set -u -t "$s" @tab_name_width 2>/dev/null || true
    return 0
  fi

  # The mode pill changes width with the mode, so reserve the widest one the
  # theme declares instead of whatever is showing right now.
  right=$(tmux display -p -t "$s" '#{T:@tab_reserve_right}' 2>/dev/null) || return 0
  [ -n "$right" ] || right=$(tmux display -p -t "$s" '#{T:status-right}' 2>/dev/null) || return 0
  width=$(
    {
      tmux display -p -t "$s" '#{T:status-left}'
      printf '%s\n' "$right"
      tmux list-windows -t "$s" -F "#{window_active}	$(printf '%s' "$tmpl" | sed 's/@W:/10:/g')	$(printf '%s' "$tmpl_cur" | sed 's/@W:/10:/g')"
    } 2>/dev/null | python3 -c "$measure" "$client"
  ) || return 0
  tmux set -t "$s" @tab_name_width "$width" 2>/dev/null || return 0

  # A window linked into several sessions shares its options between them, so
  # it takes the narrowest width among the sessions it appears in. One call per
  # window: batching them overruns tmux's message size ("command too long").
  last=
  while read -r id w; do
    [ -n "$id" ] || continue
    if [ "$w" != "$last" ]; then
      fmt=$(printf '%s' "$tmpl" | sed "s/@W:/$w:/g")
      fmt_cur=$(printf '%s' "$tmpl_cur" | sed "s/@W:/$w:/g")
      last=$w
    fi
    tmux set -w -t "$id" window-status-format "$fmt" \; \
         set -w -t "$id" window-status-current-format "$fmt_cur" 2>/dev/null || true
  done <<EOF
$(tmux list-windows -a -F '#{window_id} #{session_id} #{@tab_name_width}' | awk -v s="$s" '
  $3 != "" && (!($1 in m) || $3 + 0 < m[$1]) { m[$1] = $3 + 0 }
  $2 == s { mine[$1] = 1 }
  END { for (id in mine) if (id in m) print id, m[id] }' | sort -k2 -n)
EOF
}

if [ -n "$target" ]; then
  fit "$target"
else
  for s in $(tmux list-sessions -F '#{session_id}'); do fit "$s"; done
fi
