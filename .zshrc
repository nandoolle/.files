[[ -s "$HOME/.zsh_exports" ]] && source "$HOME/.zsh_exports"

ZSH_THEME="robbyrussell"

path=(
  $HOME/.local/bin
  $HOME/.cargo/bin
  $HOME/.asdf/shims
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
  $HOME/.zsh_alias \
  $HOME/.zsh_functions \
  $HOME/.opam/opam-init/init.zsh \
  $SDKMAN_DIR/bin/sdkman-init.sh \
  $ZSH/oh-my-zsh.sh
do
  [[ -s "$script" ]] && source "$script"
done

eval "$(zoxide init zsh)"

