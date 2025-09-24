# My Config Rig

**OS**: Windows

**Shell**: PowerShell 7

## Initializing the Repository

Remove `--force` option if you don't want to overwrite duplicates:

```pwsh
git clone --bare https://github.com/mr-valente/rig.git "$HOME/.rig"
git --git-dir="$HOME/.rig" --work-tree=$HOME checkout windows --force
. "$HOME\.config\powershell\setup.ps1"
```