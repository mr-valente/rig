# Set environment variables (permanently)

set -Ux RIG_HOME "$HOME/.rig"

set -Ux XDG_CONFIG_HOME $HOME/.config
set -Ux XDG_CACHE_HOME $HOME/.cache
set -Ux XDG_DATA_HOME $HOME/.local/share

# Restart the shell
source $XDG_CONFIG_HOME/fish/config.fish