# My Config Rig
Under construction 🚧

## Installing the repository

1. Clone and checkout repo (remove `--force` option if you don't want to overwrite duplicates)

    ```
    git clone --bare https://github.com/mr-valente/rig.git "$HOME/.rig"
    git --git-dir="$HOME/.rig" --work-tree=$HOME checkout $RIG_BRANCH --force
    ```

2. Initialize:

    * `pwsh`: 
        ```
        . "$HOME\.config\powershell\setup.ps1"
        ```

    * `fish`: 
        ```
        source "$HOME/.config/fish/setup.fish"
        ```
  
