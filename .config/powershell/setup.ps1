# Define XDG Base Directory variables
$env:XDG_CONFIG_HOME = "$HOME/.config"
$env:XDG_DATA_HOME = "$HOME/.local/share"
$env:XDG_CACHE_HOME = "$HOME/.cache"

# Set the XDG Base Directory variables in the environment
[Environment]::SetEnvironmentVariable('XDG_CONFIG_HOME', $env:XDG_CONFIG_HOME, 'User')
[Environment]::SetEnvironmentVariable('XDG_DATA_HOME', $env:XDG_DATA_HOME, 'User')
[Environment]::SetEnvironmentVariable('XDG_CACHE_HOME', $env:XDG_CACHE_HOME, 'User')

# Direct PowerShell $PROFILE to load the configuration file 
'. "$env:XDG_CONFIG_HOME\powershell\config.ps1"' | Out-File -Append -FilePath $PROFILE

# Restart the shell
. $PROFILE
