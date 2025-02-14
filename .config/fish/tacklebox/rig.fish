# This script sets up aliases and functions to manage a bare git repository
# in the user's home directory, stored at $HOME/.rig. Each function interacts
# with the "rig" alias, which is a git command configured to use the bare
# repository as its .git directory and the user's home directory as its
# working tree.
#
# rig-up
#   Description:
#     Stages and commits specified files, then pushes changes to the remote.
#   Usage:
#     rig-up [FILE_PATH ...]
#   Arguments:
#     FILE_PATH: One or more file paths (relative to $HOME) that should be staged and committed.
#   Notes:
#     - Automatically constructs a commit message noting which files were modified.
#     - Ensures that changes are pushed after committing.
#
# rig-down
#   Description:
#     Resets local changes to the current HEAD, then pulls the latest version.
#   Usage:
#     rig-down
#   Notes:
#     - Discards any uncommitted changes by resetting to HEAD.
#     - Pulls new commits from the remote repository.
#
# rig-remove
#   Description:
#     Removes specified files from tracking in the repository, commits the removal, and pushes changes.
#   Usage:
#     rig-remove [FILE_PATH ...]
#   Arguments:
#     FILE_PATH: One or more file paths (relative to $HOME) that should be removed from tracking.
#   Notes:
#     - The removal is committed with a specific message noting which files were removed.
#     - Changes are pushed to keep the repository in sync.
#
# rig-ignore
#   Description:
#     Appends specified patterns or paths to the global .gitignore, commits these changes, and pushes.
#   Usage:
#     rig-ignore [PATTERN ...]
#   Arguments:
#     PATTERN: One or more patterns or file paths to be added to the .gitignore file.
#   Notes:
#     - Updates the .gitignore in the home directory and commits the changes.
#     - Pushing ensures the ignore rules are shared across clones of the repository.

set -l RIG_HOME $HOME/.rig
set -l RIG_BRANCH "arch"

alias rig="git --git-dir=$RIG_HOME --work-tree=$HOME"

alias rig-reset="rig reset --hard HEAD"

alias rig-list="rig ls-tree -r HEAD --name-only"

function rig-push
    rig push origin $RIG_BRANCH
end

function rig-pull
    rig pull origin $RIG_BRANCH
end

function rig-up
    for arg in $argv
        rig add $HOME/$arg
        echo "Added $arg"
    end
    set commitMessage "Modified "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig-push
end

function rig-down
    rig reset --hard HEAD
    rig-pull
end

function rig-remove
    for arg in $argv
        rig rm -r --cached $HOME/$arg
        echo "Removed $arg"
    end
    set commitMessage "Removed "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig-push
end

function rig-ignore
    for arg in $argv
        echo $arg >> $HOME/.gitignore
        echo "Ignored $arg"
    end
    rig add $HOME/.gitignore
    rig commit -m "Updated .gitignore"
    rig-push
end