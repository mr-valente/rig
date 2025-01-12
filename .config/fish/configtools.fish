################################################################################
#                                                                              #
#                              Fish Toolbox                                    #
#                                                                              #
################################################################################


# Set local variables
set -l CACHE $XDG_CACHE_HOME
set -l CONFIG $XDG_CONFIG_HOME
set -l DATA $XDG_DATA_HOME
set -l DEV $HOME/.dev

set -l TACKLEBOX $CONFIG/fish/tacklebox

# Config rig functions
source $TACKLEBOX/rig.fish

# GitHub Copilot
source $TACKLEBOX/copilot.fish

# Homebrew
source $TACKLEBOX/homebrew.fish

# pyenv
source $TACKLEBOX/pyenv.fish

# Starship
source $TACKLEBOX/starship.fish

# Arch Linux / Pacman
# source $TACKLEBOX/pacman.fish