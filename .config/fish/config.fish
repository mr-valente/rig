################################################################################
#                                                                              #
#                     Fish Shell Configuration File                            #
#                                                                              #
################################################################################  

# Greeting
fish_logo cyan blue green ω Ω
set fish_greeting "Go fish !!"

# Load toolbox
source $XDG_CONFIG_HOME/fish/configtools.fish

# Launch Starship
if type -q starship
    starship init fish | source
end












