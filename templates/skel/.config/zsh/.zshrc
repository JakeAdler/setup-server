autoload -U promptinit; promptinit
autoload -Uz compinit; compinit

alias ls="ls --color=always --group-directories-first -w 60 -AHXhp"
alias ll="ls -l"
alias l="ls"

alias c="clear"
alias cdc="cd && clear"

# Lines configured by zsh-newuser-install
HISTFILE=~/.config/zsh/.history
HISTSIZE=1000
SAVEHIST=1000
unsetopt beep
bindkey -v

eval "$(starship init zsh)"
