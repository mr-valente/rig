################################################################################
#                                                                              #
#                              Fish Toolbox                                    #
#                                                                              #
################################################################################

# Set local variables
set -l RIG_HOME $HOME/.rig


# Dotfile rigging
alias rig="git --git-dir=$RIG_HOME --work-tree=$HOME"

function rig-up
    for arg in $argv
        rig add $HOME/$arg
        echo "Added $arg"
    end
    set commitMessage "Modified "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig push
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