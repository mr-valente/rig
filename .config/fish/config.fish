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

# Load toolbox
source $XDG_CONFIG_HOME/fish/configtools.fish

# Launch Homebrew shell environment
if type -q /home/linuxbrew/.linuxbrew/bin/brew
    eval (/home/linuxbrew/.linuxbrew/bin/brew shellenv)
end

# Launch Starship for 
if type -q starship; and test "$TERM" = "xterm-256color"
    starship init fish | source
end













