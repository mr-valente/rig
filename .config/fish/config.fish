################################################################################
#                                                                              #
#                     Fish Shell Configuration File                            #
#                                                                              #
################################################################################  

# Greeting
fish_logo cyan blue green ω Ω
set fish_greeting "Go fish !!"

# Set .rig and .dev directories
set RIG "$HOME/.rig"
set DEV "$HOME/.dev"

# Load aliases
source ~/.config/fish/aliases.fish

# Add CUDA binaries to PATH
# set -gx PATH /opt/cuda/bin $PATH

# Launch Starship
if type -q starship
    starship init fish | source
end












