set -U XDG_CONFIG_HOME $HOME/.config
set -U XDG_DATA_HOME $HOME/.local/share
set -U XDG_CACHE_HOME $HOME/.cache

set -U PROFILE $XDG_CONFIG_HOME/fish/config.fish

source $PROFILE