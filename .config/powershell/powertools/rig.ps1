$RIG_HOME = "$HOME\.rig"
$RIG_BRANCH = "windows"

function rig { 
    # Run git command in rig mode
    git --git-dir=$RIG_HOME --work-tree=$HOME $args 
}

function rig-push {
    # Push changes to the rig repository
    rig push origin $RIG_BRANCH
}

function rig-pull {
    # Pull changes from the rig repository
    rig pull origin $RIG_BRANCH
}

function rig-up {
    # Add files to the rig repository
	foreach ($arg in $args) {
    	rig add $HOME\$arg
		echo "Added $arg"
	}
	$commitMessage = "Modified " + ($args -join ", ")
	rig commit -m $commitMessage
	rig-push
}

function rig-down {
    # Pull changes from the rig repository
	rig reset --hard HEAD
	rig-pull
}

function rig-reset {
    # Resets the current branch to the state of the latest commit, discarding any changes made after that commit.
	rig reset --hard HEAD
}

function rig-list {
    # List all files in the rig repository
    rig ls-tree -r HEAD --name-only
}

function rig-remove {
    # Remove files from the rig repository
    foreach ($arg in $args) {
        rig rm -r --cached $HOME\$arg
        echo "Removed $arg"
    }
    $commitMessage = "Removed " + ($args -join ", ")
    rig commit -m $commitMessage
    rig-push
}

function rig-ignore {
    # Add files to the .gitignore file
    foreach ($arg in $args) {
        echo $arg | Out-File -Append -Encoding utf8 $HOME\.gitignore
        echo "Ignored $arg"
    }
    rig add $HOME\.gitignore
    rig commit -m "Updated .gitignore"
    rig-push
}

function rig-status {
    # Check status of the rig repository and provide suggestions
    
    # Fetch latest changes from remote to compare
    Write-Host "Fetching from remote..." -ForegroundColor Gray
    rig fetch origin $RIG_BRANCH 2>$null
    
    # Check for local changes
    $localStatus = rig status --porcelain
    $hasLocalChanges = $localStatus.Length -gt 0
    Write-Host "Local changes detected: $hasLocalChanges" -ForegroundColor Gray
    
    # Check for upstream changes using git status with branch info
    $branchStatus = rig status -b --porcelain=v1 2>$null
    Write-Host "Branch status output:" -ForegroundColor Gray
    $branchStatus | ForEach-Object { Write-Host "  $_" -ForegroundColor Gray }
    
    $hasUpstreamChanges = $false
    
    if ($branchStatus) {
        # Look for branch status line that indicates we're behind
        $branchLine = ($branchStatus | Where-Object { $_ -match "^##" }) -join ""
        Write-Host "Branch line: '$branchLine'" -ForegroundColor Gray
        if ($branchLine -match "\[behind \d+\]") {
            $hasUpstreamChanges = $true
        }
    }
    
    Write-Host "Upstream changes detected: $hasUpstreamChanges" -ForegroundColor Gray
    
    if ($hasLocalChanges -and $hasUpstreamChanges) {
        Write-Host "⚠️  WARNING: Both local and upstream changes detected!" -ForegroundColor Yellow
        Write-Host "Local changes:" -ForegroundColor Cyan
        rig status --short
        Write-Host "`nThis may cause a merge conflict. Suggested steps:" -ForegroundColor Yellow
        Write-Host "1. Commit your local changes: rig-up <files>" -ForegroundColor White
        Write-Host "2. Pull and merge upstream changes: rig-down" -ForegroundColor White
        Write-Host "3. Resolve any conflicts manually if they occur" -ForegroundColor White
    }
    elseif ($hasLocalChanges) {
        Write-Host "📝 Local changes detected:" -ForegroundColor Cyan
        rig status --short
        Write-Host "`nSuggestion: Run 'rig-up <files>' to commit and sync your changes" -ForegroundColor Green
    }
    elseif ($hasUpstreamChanges) {
        Write-Host "⬇️  Upstream changes available" -ForegroundColor Cyan
        Write-Host "Suggestion: Run 'rig-down' to pull the latest changes" -ForegroundColor Green
    }
    else {
        Write-Host "✅ Repository is up to date - no local or upstream changes" -ForegroundColor Green
    }
}