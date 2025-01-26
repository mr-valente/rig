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
source $TACKLEBOX/helpers.fish

# Config rig functions
source $TACKLEBOX/rig.fish

# GitHub Copilot
source $TACKLEBOX/copilot.fish

# Homebrew
# source $TACKLEBOX/homebrew.fish

# pipx
# source $TACKLEBOX/pipx.fish

# pyenv
# source $TACKLEBOX/pyenv.fish

# pacman
source $TACKLEBOX/pacman.fish

# Starship
source $TACKLEBOX/starship.fish
