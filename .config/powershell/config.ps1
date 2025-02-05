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

# Helper functions
. "$POWERTOOLS\helpers.ps1"

# Config Rig
. "$POWERTOOLS\rig.ps1"

# Starship
. "$POWERTOOLS\starship.ps1"

# Github Copilot
. "$POWERTOOLS\copilot.ps1"

# Helix
. "$POWERTOOLS\helix.ps1"

# Ghostscript
. "$POWERTOOLS\ghostscript.ps1"

# Bitwarden
. "$POWERTOOLS\bitwarden.ps1"
