# Rig - A dotfiles management system using Git bare repository
# Configuration variables
set -g RIG_HOME $HOME/.rig
set -g RIG_BRANCH "arch"

function rig
    # Execute git commands with rig repository configuration
    # Uses bare repository structure with work-tree set to $HOME
    git --git-dir=$RIG_HOME --work-tree=$HOME $argv
end

function rig-push
    # Push local commits to remote repository
    rig push origin $RIG_BRANCH
end

function rig-pull
    # Pull changes from remote repository
    rig pull origin $RIG_BRANCH
end

function rig-up
    # Stage, commit, and push specified files to the rig repository
    # Arguments: file paths relative to $HOME
    # Example: rig-up .bashrc .vimrc
    if test (count $argv) -eq 0
        echo "Error: No files specified" >&2
        return 1
    end
    
    for arg in $argv
        rig add $HOME/$arg
        echo "Added $arg"
    end
    set -l commitMessage "Modified "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig-push
end

function rig-down
    # Synchronize local repository with remote changes
    # Performs hard reset, fetch, and merge to ensure clean state
    rig reset --hard HEAD
    # Use explicit refspec to update remote branch reference
    rig fetch origin "$RIG_BRANCH:refs/remotes/origin/$RIG_BRANCH"
    rig merge "origin/$RIG_BRANCH"
end

function rig-reset
    # Reset repository to latest commit, discarding all local changes
    # WARNING: This will permanently discard uncommitted changes
    rig reset --hard HEAD
end

function rig-list
    # List all tracked files in the rig repository
    rig ls-tree -r HEAD --name-only
end

function rig-remove
    # Remove files from rig repository tracking and push changes
    # Arguments: file paths relative to $HOME
    # Note: Files remain in filesystem but are no longer tracked
    if test (count $argv) -eq 0
        echo "Error: No files specified" >&2
        return 1
    end
    
    for arg in $argv
        rig rm -r --cached $HOME/$arg
        echo "Removed $arg"
    end
    set -l commitMessage "Removed "(string join ", " $argv)
    rig commit -m "$commitMessage"
    rig-push
end

function rig-ignore
    # Add patterns to .gitignore and commit the changes
    # Arguments: file patterns or paths to ignore
    # Example: rig-ignore "*.log" "temp/"
    if test (count $argv) -eq 0
        echo "Error: No files specified" >&2
        return 1
    end
    
    for arg in $argv
        echo $arg >>$HOME/.gitignore
        echo "Ignored $arg"
    end
    rig add $HOME/.gitignore
    rig commit -m "Updated .gitignore"
    rig-push
end

function rig-status
    # Analyze repository status and provide actionable recommendations
    # Options:
    #   --quiet, -q: Show minimal output for scripting
    # Checks for both local uncommitted changes and upstream updates
    set -l quiet_mode false
    
    # Parse command line options
    for arg in $argv
        if test "$arg" = "--quiet" -o "$arg" = "-q"
            set quiet_mode true
            break
        end
    end
    
    # Display progress information in verbose mode
    if test "$quiet_mode" = false
        set_color brblack
        echo "Checking rig repository status..."
        set_color normal
    end
    
    # Fetch latest remote changes with explicit refspec
    if test "$quiet_mode" = false
        set_color brblack
        echo "Fetching from remote..."
        set_color normal
    end
    rig fetch origin "$RIG_BRANCH:refs/remotes/origin/$RIG_BRANCH" 2>/dev/null
    
    # Detect local uncommitted changes
    set -l local_status (rig status --porcelain 2>/dev/null)
    set -l has_local_changes false
    if test -n "$local_status"
        set has_local_changes true
    end
    if test "$quiet_mode" = false
        set_color brblack
        echo "Local changes detected: $has_local_changes"
        set_color normal
    end
    
    # Get commit hashes for comparison
    set -l local_commit (rig rev-parse HEAD 2>/dev/null)
    if test "$quiet_mode" = false
        set_color brblack
        echo "Local commit: $local_commit"
        set_color normal
    end
    
    set -l remote_commit (rig rev-parse "origin/$RIG_BRANCH" 2>/dev/null)
    if test "$quiet_mode" = false
        set_color brblack
        echo "Remote commit: $remote_commit"
        set_color normal
    end
    
    # Determine if remote has newer commits
    set -l has_upstream_changes false
    if test -n "$local_commit" -a -n "$remote_commit" -a "$local_commit" != "$remote_commit"
        set has_upstream_changes true
    end
    if test "$quiet_mode" = false
        set_color brblack
        echo "Upstream changes detected: $has_upstream_changes"
        set_color normal
    end
    
    # Provide status summary and recommendations
    if test "$has_local_changes" = true -a "$has_upstream_changes" = true
        if test "$quiet_mode" = true
            set_color yellow
            echo "rig: local and upstream changes detected"
            set_color normal
        else
            echo ""
            set_color yellow
            echo "⚠️  WARNING: Both local and upstream changes detected!"
            set_color cyan
            echo "Local changes:"
            set_color normal
            rig status --short
            set_color yellow
            echo ""
            echo "This may cause a merge conflict. Suggested steps:"
            set_color white
            echo "1. Commit your local changes: rig-up <files>"
            echo "2. Pull and merge upstream changes: rig-down"
            echo "3. Resolve any conflicts manually if they occur"
            set_color normal
        end
    else if test "$has_local_changes" = true
        if test "$quiet_mode" = true
            set_color cyan
            echo "rig: local changes pending"
            set_color normal
        else
            echo ""
            set_color cyan
            echo "📝 Local changes detected:"
            set_color normal
            rig status --short
            set_color green
            echo ""
            echo "Suggestion: Run 'rig-up <files>' to commit and sync your changes"
            set_color normal
        end
    else if test "$has_upstream_changes" = true
        if test "$quiet_mode" = true
            set_color cyan
            echo "rig: upstream changes available"
            set_color normal
        else
            echo ""
            set_color cyan
            echo "⬇️  Upstream changes available"
            set_color green
            echo "Suggestion: Run 'rig-down' to pull the latest changes"
            set_color normal
        end
    else
        if test "$quiet_mode" = false
            echo ""
            set_color green
            echo "✅ Repository is up to date - no local or upstream changes"
            set_color normal
        end
        # Silent success in quiet mode when everything is synchronized
    end
end