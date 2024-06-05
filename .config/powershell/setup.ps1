# Loads the configuration for powershell
'."$HOME/.config/powershell/config.ps1"'| Out-File -Append -FilePath $PROFILE

# Restart the shell
.$PROFILE
