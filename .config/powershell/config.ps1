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

# Load toolbox
. "$env:XDG_CONFIG_HOME\powershell\configtools.ps1"

$XDG_CONFIG_HOME = $env:XDG_CONFIG_HOME
$XDG_DATA_HOME = $env:XDG_DATA_HOME
$XDG_CACHE_HOME = $env:XDG_CACHE_HOME

# Check if Starship exists
if (Get-Command starship -ErrorAction SilentlyContinue) {
    # Launch Starship
    Invoke-Expression (&starship init powershell)
}