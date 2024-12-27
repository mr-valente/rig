# Define XDG Base Directory variables
$env:XDG_CONFIG_HOME = "$HOME\.config"
$env:XDG_DATA_HOME = "$HOME\.local\share"
$env:XDG_CACHE_HOME = "$HOME\.cache"

# Set the XDG Base Directory variables in the environment
[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $env:XDG_CONFIG_HOME, 'User')
[Environment]::SetEnvironmentVariable('XDG_DATA_HOME', $env:XDG_DATA_HOME, 'User')
[Environment]::SetEnvironmentVariable('XDG_CACHE_HOME', $env:XDG_CACHE_HOME, 'User')

# Direct PowerShell $PROFILE to launch the configuration file 
$launchcode = '. "$env:XDG_CONFIG_HOME\powershell\config.ps1"'

# If $PROFILE does not contain launch code, append it
if ((Get-Content $PROFILE) -notcontains $launchcode) {
    $launchcode | Out-File -Append -FilePath $PROFILE
}

# Restart the shell
. $PROFILE

# Set up .gitconfig
rig config --global core.autocrlf false
rig config --global push.autoSetupRemote true
rig config --global status.showUntrackedFiles no