################################################################################
#                                                                              #
#                     PowerShell Configuration File                            #
#                                                                              #
################################################################################

# Greeting
write-host "
 ╦ ╦┌─┐┬  ┌─┐┌─┐┌┬┐┌─┐  ┌┬┐┌─┐  ╔═╗┌─┐┌─┐┌─┐┌─┐┌─┐┬ ┬┬┌─┐  ╔═╗┌─┐┬─┐┌┬┐┬ ┬
 ║║║├┤ │  │  │ ││││├┤    │ │ │  ╚═╗├─┘├─┤│  ├┤ └─┐├─┤│├─┘  ║╣ ├─┤├┬┘ │ ├─┤
 ╚╩╝└─┘┴─┘└─┘└─┘┴ ┴└─┘   ┴ └─┘  ╚═╝┴  ┴ ┴└─┘└─┘└─┘┴ ┴┴┴    ╚═╝┴ ┴┴└─ ┴ ┴ ┴"

# Set home variables
$DESKTOP = "$HOME\Desktop"
$DOCUMENTS = "$HOME\Documents"
$DOWNLOADS = "$HOME\Downloads"
$MUSIC = "$HOME\Music"
$PICTURES = "$HOME\Pictures"
$VIDEOS = "$HOME\Videos"

$POWERTOOLS = "$env:XDG_CONFIG_HOME\powershell\powertools"	
. "$POWERTOOLS\helpers.ps1"	    # Helper functions
. "$POWERTOOLS\rig.ps1"         # Config Rig
. "$POWERTOOLS\starship.ps1"    # Starship
. "$POWERTOOLS\copilot.ps1"     # GitHub Copilot
. "$POWERTOOLS\helix.ps1"       # Helix
. "$POWERTOOLS\ghostscript.ps1" # Ghostscript
. "$POWERTOOLS\bitwarden.ps1"   # Bitwarden
. "$POWERTOOLS\tailscale.ps1"   # Tailscale

# Check rig status
rig-status -Quiet
