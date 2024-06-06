################################################################################
#                                                                              #
#                              Fish Aliases                                    #
#                                                                              #
################################################################################

# Set .rig and .dev directories
set RIG "$HOME/.rig"
set DEV "$HOME/.dev"

# General
alias rig="git --git-dir=$RIG --work-tree=$HOME"

# Arch Linux / Pacman
alias pacplay="sudo pacman -Syu"
alias pacsearch="sudo pacman -Ss"
alias pacslay="sudo pacman -Rs"
alias packey="pacman -Sy archlinux-keyring && pacman -Su"