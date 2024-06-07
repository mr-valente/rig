################################################################################
#                                                                              #
#                              Fish Aliases                                    #
#                                                                              #
################################################################################

# Set environment variables
set RIG "$HOME/.rig"
set DEV "$HOME/.dev"

# Dotfile rigging
alias rig="git --git-dir=$RIG --work-tree=$HOME"

function rig-up
    for arg in $argv
        rig add $HOME/$arg
        echo "Added $arg"
    end
    set commitMessage "Modified "(string join ", " $argv)
    rig commit -m "$commitMessage"
end

function rig-down
    rig reset --hard HEAD
    rig pull
end


# GitHub Copilot
alias suggest="gh copilot suggest"
alias explain="gh copilot explain"


# Arch Linux / Pacman
alias pacplay="sudo pacman -Syu"
alias pacsearch="sudo pacman -Ss"
alias pacslay="sudo pacman -Rs"
alias packey="pacman -Sy archlinux-keyring && pacman -Su"