# ~/.zshrc

# Lazy-load antidote and generate the static load file only when needed
zsh_plugins=${ZDOTDIR:-$HOME}/.zsh_plugins

if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  (
    source $(brew --prefix antidote)/share/antidote/antidote.zsh
    antidote bundle <${zsh_plugins}.txt >${zsh_plugins}.zsh
  )
fi

source ${zsh_plugins}.zsh
source $(brew --prefix)/share/powerlevel10k/powerlevel10k.zsh-theme

# custom config
for file in ${HOME}/.zsh/*.zsh; do
  source $file
done

# custom completions
fpath+=~/.zsh/completions/
autoload -Uz compinit && compinit