# Nick's Config Rig
Under construction 🚧

## Installing the repository

### Powershell

```powershell
git clone --bare https://github.com/mr-valente/rig.git "$HOME\.rig"
git --git-dir="$HOME\.rig" --work-tree=$HOME checkout --force
. "$HOME\.config\powershell\setup.ps1"
```

### Fish

```fish
git clone --bare https://github.com/mr-valente/rig.git "$HOME/.rig"
git --git-dir="$HOME/.rig" --work-tree=$HOME checkout --force
source "$HOME/.config/fish/setup.fish"
```
  