################################################################################
#                                                                              #
#                           PowerShell Toolbox                                 #
#                                                                              #
################################################################################

# Set XDG variables
$CACHE = $env:XDG_CACHE_HOME
$CONFIG = $env:XDG_CONFIG_HOME
$DATA = $env:XDG_DATA_HOME

# Set dev variables
$DEV = "$HOME\.dev"

# Set home variables
$DESKTOP = "$HOME\Desktop"
$DOCUMENTS = "$HOME\Documents"
$DOWNLOADS = "$HOME\Downloads"
$MUSIC = "$HOME\Music"
$PICTURES = "$HOME\Pictures"
$VIDEOS = "$HOME\Videos"


$POWERTOOLS = "$CONFIG\powershell\powertools"

# Helper functions
. "$POWERTOOLS\helpers.ps1"

# Config Rig
. "$POWERTOOLS\rig.ps1"

# Github Copilot
if (CommandExists "gh") {
    . "$POWERTOOLS\copilot.ps1"
}

# Helix
if (CommandExists "hx") {
    . "$POWERTOOLS\helix.ps1"
}

# Ghostscript
if (CommandExists "gs") {    
    . "$POWERTOOLS\ghostscript.ps1"
}

# Bitwarden
if (CommandExists "bw") {
    . "$POWERTOOLS\bitwarden.ps1"
}


