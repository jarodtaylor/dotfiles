#!/usr/bin/env zsh

alias ls="eza --all --icons --no-permissions --git --header --no-user --classify --group-directories-first"
alias ll="ls -lh"
alias lt='ls --tree'
alias lart='ll --sort=mod'
alias rd='rmdir'
alias tree='eza -T --level=5'
alias reload='source $ZDOTDIR/.zshrc; echo -e "\n\u2699  \e[33mZSH config reloaded\e[0m \u2699"'