# My Config Rig

**OS**: Arch Linux 

**Shell**: Fish

## Initializing the Repository

Remove `--force` option if you don't want to overwrite duplicates:

```fish
git clone --bare https://github.com/mr-valente/rig.git "$HOME/.rig"
git --git-dir="$HOME/.rig" --work-tree=$HOME checkout arch --force
source $HOME/.config/fish/setup.fish
```