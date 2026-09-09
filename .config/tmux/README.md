# tmux-config

A tmux configuration: base settings, vi-style keybindings, session persistence
via TPM plugins, and a three-line status bar with system and LLM usage stats.

## Requirements

- tmux >= 3.1 (needed for the XDG config path, `~/.config/tmux/tmux.conf`)
- [TPM](https://github.com/tmux-plugins/tpm) (tmux Plugin Manager)
- `jq`
- A Nerd Font (for status bar glyphs)
- The LLM usage segments (`#{vitals_llm}`) come from the
  [`tmux-vitals`](https://github.com/k8adev/tmux-vitals) plugin — see its
  README for what it needs, including the Claude Code statusLine hook that
  writes the usage cache. `tmux-vitals` in turn requires `tmux-plugins/tmux-cpu` (both pulled in via
  `@plugin` lines in `tmux.conf`).

## Install

```sh
git clone https://github.com/k8adev/tmux-config ~/.config/tmux
```

If a `~/.tmux.conf` exists, move it out of the way — tmux loads that legacy
path in preference to `~/.config/tmux/tmux.conf`, so the new config would
silently never run:

```sh
mv ~/.tmux.conf ~/.tmux.conf.bak
```

Then start tmux and press `prefix + I` to let TPM install the plugins
(the theme included). Reload an already-running tmux with:

```sh
tmux source-file ~/.config/tmux/tmux.conf
```

## Status bar

`scripts/statusbar.sh` runs after TPM (via `run-shell` at the bottom of
`tmux.conf`) and builds a 3-line status bar:

1. A blank spacer line, so the bar is not glued to the pane above.
2. The theme's own status line, plus the resurrect save age
   (`scripts/resurrect-age.sh`) in front of the session name.
3. The vitals line: `#{vitals_llm}` (Claude/ChatGPT usage) on the left,
   `#{vitals_system}` (CPU/RAM/net/battery) on the right.

`resurrect-age.sh` lives in this repo now that the theme is colors-only — it
used to be rendered by the theme itself.

## Theme

The color theme is a separate TPM plugin, `k8adev/hyper-term-black.tmux`
(pulled in via the `@plugin` line in `tmux.conf`) — it is not vendored into
this repo, and this repo only references it through that `@plugin` line.
