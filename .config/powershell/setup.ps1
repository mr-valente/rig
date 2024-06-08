# Direct PowerShell $PROFILE to load the configuration file 
'. "$HOME\.config\powershell\config.ps1"' | Out-File -Append -FilePath $PROFILE

# Restart the shell
. $PROFILE
