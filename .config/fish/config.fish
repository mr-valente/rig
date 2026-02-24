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
for f in $TACKLEBOX/*.fish
    source $f
end

# (temporary) Disable Config Rig status prompt
rig-status --quiet

###############################################################################
# (temporary) Function to check Arch LTS kernel version

function check_lts --description "Check if Arch LTS kernel is 6.18+"
    # Fetch the version
    set -l current_lts (curl -s "https://archlinux.org/packages/search/json/?name=linux-lts" | jq -r ".results[0].pkgver")
    
    # Check if version is 6.18 or higher
    # Regex explanation:
    # ^6\.       = Starts with "6."
    # 1[8-9]     = Matches 18 or 19
    # |          = OR
    # [2-9][0-9] = Matches 20 through 99
    if string match -qr "^6\.(1[8-9]|[2-9][0-9])" -- $current_lts
        set_color -o green
        echo ""
        echo "🚨 ALERT: Linux LTS has updated to $current_lts!"
        echo ""
        set_color normal
    end
end

check_lts