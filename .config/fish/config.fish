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
source $TACKLEBOX/helpers.fish      # Helper functions
source $TACKLEBOX/rig.fish          # Config Rig
source $TACKLEBOX/copilot.fish      # GitHub Copilot
source $TACKLEBOX/pacman.fish       # Pacman
source $TACKLEBOX/starship.fish     # Starship

rig-status --quiet