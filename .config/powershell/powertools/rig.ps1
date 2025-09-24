# Rig - A dotfiles management system using Git bare repository
# Configuration variables
$RIG_HOME = "$HOME\.rig"
$RIG_BRANCH = "windows"

function rig { 
    # Execute git commands with rig repository configuration
    # Uses bare repository structure with work-tree set to $HOME
    git --git-dir=$RIG_HOME --work-tree=$HOME $args 
}

function rig-push {
    # Push local commits to remote repository
    rig push origin $RIG_BRANCH
}

function rig-pull {
    # Pull changes from remote repository
    rig pull origin $RIG_BRANCH
}

function rig-up {
    # Stage, commit, and push specified files to the rig repository
    # Arguments: file paths relative to $HOME
    # Example: rig-up .bashrc .vimrc
    if ($args.Count -eq 0) {
        Write-Error "Error: No files specified"
        return 1
    }
    
    foreach ($arg in $args) {
        rig add "$HOME\$arg"
        Write-Host "Added $arg"
    }
    $commitMessage = "Modified " + ($args -join ", ")
    rig commit -m $commitMessage
    rig-push
}

function rig-down {
    # Synchronize local repository with remote changes
    # Performs hard reset, fetch, and merge to ensure clean state
    rig reset --hard HEAD
    # Use explicit refspec to update remote branch reference
    rig fetch origin "${RIG_BRANCH}:refs/remotes/origin/${RIG_BRANCH}"
    rig merge "origin/$RIG_BRANCH"
}

function rig-reset {
    # Reset repository to latest commit, discarding all local changes
    # WARNING: This will permanently discard uncommitted changes
    rig reset --hard HEAD
}

function rig-list {
    # List all tracked files in the rig repository
    rig ls-tree -r HEAD --name-only
}

function rig-remove {
    # Remove files from rig repository tracking and push changes
    # Arguments: file paths relative to $HOME
    # Note: Files remain in filesystem but are no longer tracked
    if ($args.Count -eq 0) {
        Write-Error "Error: No files specified"
        return 1
    }
    
    foreach ($arg in $args) {
        rig rm -r --cached "$HOME\$arg"
        Write-Host "Removed $arg"
    }
    $commitMessage = "Removed " + ($args -join ", ")
    rig commit -m $commitMessage
    rig-push
}

function rig-ignore {
    # Add patterns to .gitignore and commit the changes
    # Arguments: file patterns or paths to ignore
    # Example: rig-ignore "*.log" "temp/"
    if ($args.Count -eq 0) {
        Write-Error "Error: No files specified"
        return 1
    }
    
    foreach ($arg in $args) {
        Add-Content -Path "$HOME\.gitignore" -Value $arg -Encoding UTF8
        Write-Host "Ignored $arg"
    }
    rig add "$HOME\.gitignore"
    rig commit -m "Updated .gitignore"
    rig-push
}

function rig-status {
    # Analyze repository status and provide actionable recommendations
    # Options:
    #   -Quiet: Show minimal output for scripting
    # Checks for both local uncommitted changes and upstream updates
    param(
        [switch]$Quiet
    )
    
    # Display progress information in verbose mode
    if (-not $Quiet) {
        Write-Host "Checking rig repository status..." -ForegroundColor DarkGray
    }
    
    # Fetch latest remote changes with explicit refspec
    if (-not $Quiet) {
        Write-Host "Fetching from remote..." -ForegroundColor DarkGray
    }
    rig fetch origin "${RIG_BRANCH}:refs/remotes/origin/${RIG_BRANCH}" 2>$null
    
    # Detect local uncommitted changes
    $localStatus = rig status --porcelain 2>$null
    $hasLocalChanges = ($localStatus -and $localStatus.Length -gt 0)
    if (-not $Quiet) {
        Write-Host "Local changes detected: $hasLocalChanges" -ForegroundColor DarkGray
    }
    
    # Get commit hashes for comparison
    $localCommit = rig rev-parse HEAD 2>$null
    if (-not $Quiet) {
        Write-Host "Local commit: $localCommit" -ForegroundColor DarkGray
    }
    
    $remoteCommit = rig rev-parse "origin/$RIG_BRANCH" 2>$null
    if (-not $Quiet) {
        Write-Host "Remote commit: $remoteCommit" -ForegroundColor DarkGray
    }
    
    # Determine if remote has newer commits
    $hasUpstreamChanges = ($localCommit -and $remoteCommit -and $localCommit -ne $remoteCommit)
    if (-not $Quiet) {
        Write-Host "Upstream changes detected: $hasUpstreamChanges" -ForegroundColor DarkGray
    }
    
    # Provide status summary and recommendations
    if ($hasLocalChanges -and $hasUpstreamChanges) {
        if ($Quiet) {
            Write-Host "rig: local and upstream changes detected" -ForegroundColor Yellow
        } else {
            Write-Host "`n⚠️  WARNING: Both local and upstream changes detected!" -ForegroundColor Yellow
            Write-Host "Local changes:" -ForegroundColor Cyan
            rig status --short
            Write-Host "`nThis may cause a merge conflict. Suggested steps:" -ForegroundColor Yellow
            Write-Host "1. Commit your local changes: rig-up <files>" -ForegroundColor White
            Write-Host "2. Pull and merge upstream changes: rig-down" -ForegroundColor White
            Write-Host "3. Resolve any conflicts manually if they occur" -ForegroundColor White
        }
    }
    elseif ($hasLocalChanges) {
        if ($Quiet) {
            Write-Host "rig: local changes pending" -ForegroundColor Cyan
        } else {
            Write-Host "`n📝 Local changes detected:" -ForegroundColor Cyan
            rig status --short
            Write-Host "`nSuggestion: Run 'rig-up <files>' to commit and sync your changes" -ForegroundColor Green
        }
    }
    elseif ($hasUpstreamChanges) {
        if ($Quiet) {
            Write-Host "rig: upstream changes available" -ForegroundColor Cyan
        } else {
            Write-Host "`n⬇️  Upstream changes available" -ForegroundColor Cyan
            Write-Host "Suggestion: Run 'rig-down' to pull the latest changes" -ForegroundColor Green
        }
    }
    else {
        if (-not $Quiet) {
            Write-Host "`n✅ Repository is up to date - no local or upstream changes" -ForegroundColor Green
        }
        # Silent success in quiet mode when everything is synchronized
    }
}