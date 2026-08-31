set -U XDG_CONFIG_HOME $HOME/.config
set -U XDG_DATA_HOME $HOME/.local/share
set -U XDG_CACHE_HOME $HOME/.cache

set -U PROFILE $XDG_CONFIG_HOME/fish/config.fish

source $PROFILE

# Set up global .gitconfig
rig config --global core.autocrlf false
rig config --global push.autoSetupRemote true
rig config --global init.defaultBranch main

# Set up local .gitconfig
rig config --local status.showUntrackedFiles no

# Configure rig repository for proper remote branch tracking
echo "Configuring rig repository for remote branch tracking..."
rig config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
rig fetch origin
echo "✅ Rig repository configured successfully"
