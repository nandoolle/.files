# tmux

A native tmux configuration. The status bar is built entirely from tmux's own
format language -- there is no `#()` shell call anywhere in it, so a status
tick costs nothing. Shell scripts run only on a keypress, a click, or a
geometry change.

Started as a fork of [k8adev/tmux-config](https://github.com/k8adev/tmux-config),
since rewritten; nothing of the original setup remains.

## Layout

| File | What it is |
| --- | --- |
| `tmux.conf` | Root config: bindings, options, mouse, hooks. Sources the rest. |
| `tokyo-night.conf` | The whole theme and status bar, native formats only. |
| `move-mode.tmux` | MOVE mode -- a self-contained modal plugin. |
| `ai-mode.tmux` | AI mode -- one-key `claude -p` calls. |
| `icons.conf` | Generated per-command icons. Committed output, do not edit. |
| `tools/` | The scripts behind the tabs, the icons and AI mode. |

## Modes

Both modes set the `key-table` option rather than `switch-client -T`, which is
what makes them sticky and visible: the active table is rendered in the status
bar via `#{client_key_table}`. In either mode, `Escape` steps back one level
and any unmapped key leaves the mode entirely, so a stray keystroke can never
run a normal binding while the bar still reads MOVE.

### MOVE -- `prefix + m`

| Submode | Keys |
| --- | --- |
| MOVE | `hjkl` panes, `HL` windows, `JK` sessions, `W`/`P`/`R` submodes (either case) |
| MOVE-PANE | `hk`/`jl` reorder, `HL` to prev/next window, `J` to a session, `K` break out |
| MOVE-WINDOW | `hl` reorder, `J` to another session, `K` to a new session |
| RESIZE | `hjkl`, one cell per press |

### AI -- `prefix + a`

The next key picks an action and leaves the mode. Everything runs in the
background, with a spinner in the status bar; a keypress never blocks on the
model.

| Key | Action |
| --- | --- |
| `l` | Summarise open Linear issues into `linear/notes.md` |
| `c` | Summarise the current ClickUp sprint (Technology board) into `clickup/notes.md` |
| `t` | Rename every window after the work in it (max 30 chars) |
| `s` | Re-check the noted tasks and tick the finished ones |
| `m` | Set the model for these calls (empty = the CLI default) |

**What leaves the machine:** `l`/`c`/`s` send tracker data to the model, and
`t` sends each pane's visible screen.

## Notes popup

`prefix + n`, or the icon on the right of the tab bar, toggles a floating nvim
on `~/.menunotes.tmux/notes/notes.md`. The popup is a client attached to a
dedicated `notes` session, which is what keeps nvim alive between openings.
That directory must exist and be a git repo -- AI mode writes into it, and
`sync.sh` commits before rewriting anything.

```sh
mkdir -p ~/.menunotes.tmux/notes && git -C ~/.menunotes.tmux/notes init
```

## Elastic tabs

Tabs stretch to fill the bar. tmux's `#{pN:}` padding takes a literal number
and never an expression, so the width cannot be computed at render time:
`tokyo-night.conf` ships a `#{p@W:}` placeholder, and `tools/fit-tabs.sh`
rewrites the two `window-status-*` options from a stashed pristine template.

It is not a daemon. tmux itself runs it, from three hooks only --
`window-linked`, `window-unlinked` and `client-resized` -- plus once at
startup. It takes about 0.2s and exits.

Left click on a tab selects it; middle click closes it.

## Icons

`icons.conf` maps `#{pane_current_command}` to a glyph and a colour, as a plain
nested `#{?...}` chain -- zero runtime cost. It is generated, not written:

```sh
tools/gen-icons.py            # refetch nvim-web-devicons
tools/gen-icons.py --offline  # reuse the cached copy
```

Edit `tools/icons.map` to add a command, then regenerate. The map's left column
is the process name tmux reports, the right one a devicons key; a third column
overrides the colour, and a `=` prefix gives a literal glyph instead.

## Requirements

- tmux -- developed against 3.6
- A Nerd Font (JetBrains Nerd Font here)
- `python3`, for the display-width helper in `fit-tabs.sh` and for `gen-icons.py`
- `nvim`, for the notes popup
- `claude` CLI with the Linear and ClickUp MCPs, for AI mode
- TPM, bootstrapped at the bottom of `tmux.conf`. It currently manages no
  plugins beyond itself.
