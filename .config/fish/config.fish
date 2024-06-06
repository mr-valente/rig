################################################################################
#                                                                              #
#                     Fish Shell Configuration File                            #
#                                                                              #
################################################################################  

# Greeting
fish_logo cyan blue green ω Ω
set fish_greeting "Go fish !!"

# Load aliases
source ~/.config/fish/configtools.fish

# Add CUDA binaries to PATH
# set -gx PATH /opt/cuda/bin $PATH

# Launch Starship
if type -q starship
    starship init fish | source
end












