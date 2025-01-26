set -U XDG_CONFIG_HOME $HOME/.config
set -U XDG_DATA_HOME $HOME/.local/share
set -U XDG_CACHE_HOME $HOME/.cache

set -U PROFILE $XDG_CONFIG_HOME/fish/config.fish

source $PROFILE

# Set up .gitconfig
rig config --global core.autocrlf false
rig config --global push.autoSetupRemote true
rig config --global status.showUntrackedFiles no
rig config --global init.defaultBranch main