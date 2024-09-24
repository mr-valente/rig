################################################################################
#                                                                              #
#                              Fish Toolbox                                    #
#                                                                              #
################################################################################

# Set XDG Base Directories
set -gx XDG_CONFIG_HOME $HOME/.config
set -gx XDG_DATA_HOME $HOME/.local/share
set -gx XDG_CACHE_HOME $HOME/.cache

# Set local variables
set -l DEV $HOME/.dev
set -l RIG_HOME $HOME/.rig

# Config rig functions
alias rig="git --git-dir=$RIG_HOME --work-tree=$HOME"
alias rig-reset="rig reset --hard HEAD"
alias rig-list="rig ls-tree -r HEAD --name-only"

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

function rig-remove
    for arg in $argv
        rig rm --cached $HOME\$arg
        echo "Removed $arg"
    end
    set commitMessage "Removed "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig push
end

function rig-ignore
    for arg in $argv
        echo $arg >> $HOME/.gitignore
        echo "Ignored $arg"
    end
    rig add $HOME/.gitignore
    rig commit -m "Updated .gitignore"
    rig push
end



# GitHub Copilot
alias suggest="gh copilot suggest"
alias explain="gh copilot explain"


# Arch Linux / Pacman
alias pacplay="sudo pacman -Syu"
alias pacsearch="sudo pacman -Ss"
alias pacslay="sudo pacman -Rs"
alias packey="pacman -Sy archlinux-keyring && pacman -Su"