[[ -s "$HOME/.zsh_exports" ]] && source "$HOME/.zsh_exports"

ZSH_THEME="robbyrussell"

path=(
  $PNPM_HOME/bin
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/.asdf/shims
  $HOME/.npm-global/bin
  $path
)
plugins=(
    git
    npm
    dotenv
    1password
    you-should-use
    zsh-autosuggestions
    zsh-syntax-highlighting
)

for script in \
  $ZSH/oh-my-zsh.sh \
  $HOME/.zsh_alias \
  $HOME/.zsh_functions \
  $HOME/.opam/opam-init/init.zsh \
  $SDKMAN_DIR/bin/sdkman-init.sh
do
  [[ -s "$script" ]] && source "$script"
done

eval "$(zoxide init zsh)"


# bun completions
[ -s "/Users/fernandoolle/.bun/_bun" ] && source "/Users/fernandoolle/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"


if command -v wt >/dev/null 2>&1; then eval "$(command wt config shell init zsh)"; fi
