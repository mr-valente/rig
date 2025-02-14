################################################################################
#                                                                              #
#                     Fish Shell Configuration File                            #
#                                                                              #
################################################################################  

# Greeting
# fish_logo cyan blue green ω Ω
set -g fish_greeting "
 ╦ ╦┌─┐┬  ┌─┐┌─┐┌┬┐┌─┐  ┌┬┐┌─┐  ╔═╗┌─┐┌─┐┌─┐┌─┐┌─┐┬ ┬┬┌─┐  ╔═╗┌─┐┬─┐┌┬┐┬ ┬
 ║║║├┤ │  │  │ ││││├┤    │ │ │  ╚═╗├─┘├─┤│  ├┤ └─┐├─┤│├─┘  ║╣ ├─┤├┬┘ │ ├─┤
 ╚╩╝└─┘┴─┘└─┘└─┘┴ ┴└─┘   ┴ └─┘  ╚═╝┴  ┴ ┴└─┘└─┘└─┘┴ ┴┴┴    ╚═╝┴ ┴┴└─ ┴ ┴ ┴"

set -l TACKLEBOX $XDG_CONFIG_HOME/fish/tacklebox


# Helper functions
# source $TACKLEBOX/helpers.fish
function reload
    clear
    fish_greeting
    source $PROFILE
    # If a directory is passed, cd to it
    if test -d $argv[1]
        cd $argv[1]
    end
end

function exists
    type -q $argv[1]
end

# Pretty print PATH with each entry on a new line
function path
    for p in $PATH
        echo $p
    end
end


# Config rig functions
# source $TACKLEBOX/rig.fish
set -l RIG_HOME $HOME/.rig
set -l RIG_BRANCH "ubuntu"

alias rig="git --git-dir=$RIG_HOME --work-tree=$HOME"

alias rig-reset="rig reset --hard HEAD"

alias rig-list="rig ls-tree -r HEAD --name-only"

function rig-push
    rig push origin $RIG_BRANCH
end

function rig-pull
    rig pull origin $RIG_BRANCH
end

function rig-up
    for arg in $argv
        rig add $HOME/$arg
        echo "Added $arg"
    end
    set commitMessage "Modified "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig-push
end

function rig-down
    rig reset --hard HEAD
    rig-pull
end

function rig-remove
    for arg in $argv
        rig rm --cached $HOME/$arg
        echo "Removed $arg"
    end
    set commitMessage "Removed "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig-push
end

function rig-ignore
    for arg in $argv
        echo $arg >> $HOME/.gitignore
        echo "Ignored $arg"
    end
    rig add $HOME/.gitignore
    rig commit -m "Updated .gitignore"
    rig-push
end


# GitHub Copilot
# source $TACKLEBOX/copilot.fish


# Homebrew
# source $TACKLEBOX/homebrew.fish
if exists /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end


# pipx
# source $TACKLEBOX/pipx.fish
fish_add_path $HOME/.local/bin


# pyenv
# source $TACKLEBOX/pyenv.fish
if exists $HOME/.pyenv/bin/pyenv
    set -l PYENV_ROOT $HOME/.pyenv
    fish_add_path $PYENV_ROOT/bin
    # pyenv init - | source
    # pyenv init --path | source
end


# Starship
# source $TACKLEBOX/starship.fish
if exists starship 
    and test "$TERM" = xterm-256color
    starship init fish | source
end