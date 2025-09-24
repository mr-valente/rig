# My Config Rig

A simple yet powerful dotfiles management system using Git bare repositories. Rig allows you to version control your configuration files across different operating systems and shells without cluttering your home directory with a `.git` folder.

## Features

- **Cross-platform** with OS-specific branches
- **Simple command interface** for managing dotfiles
- **Git-based** version control with remote synchronization
- **Bare repository structure** keeps your home directory clean
- **Status monitoring** with conflict detection and recommendations

## Usage

Navigate to an OS-specific branch for rig files and initialization instructions. 

### Commands

| Command | Description |
|---------|-------------|
| `rig <git-command>` | Execute any git command on the rig repository |
| `rig-up <files...>` | Add, commit, and push specified files in your home directory|
| `rig-down` | Pull and merge remote changes |
| `rig-push` | Push local commits to remote |
| `rig-pull` | Pull changes from remote |
| `rig-status` | Show status with recommendations |
| `rig-list` | List all tracked files |
| `rig-remove <files...>` | Stop tracking specified files |
| `rig-ignore <patterns...>` | Add patterns to .gitignore |
| `rig-reset` | Reset to latest commit (discards local changes) |

### Usage Examples

```powershell
# Track new configuration files
rig-up .vimrc .gitconfig

# Check what needs attention
rig-status

# Pull latest changes from remote
rig-down

# View all tracked files
rig-list

# Stop tracking a file (but keep it locally)
rig-remove .old-config

# Ignore temporary files
rig-ignore "*.tmp" "cache/"
```

## How It Works

Rig uses a Git bare repository stored in `$HOME/.rig` with your home directory as the working tree. This approach:

- Keeps your home directory clean (no `.git` folder)
- Allows normal Git operations on your dotfiles
- Enables easy synchronization across machines
- Supports branching for different OS/shell configurations

## Setup for Other Platforms

To create support for additional platforms, create new branches in your fork:

```bash
git checkout -b linux-bash
# Add your Linux/Bash configurations
git checkout -b macos-zsh  
# Add your macOS/Zsh configurations
```

## License

This project is provided as-is for personal dotfiles management.