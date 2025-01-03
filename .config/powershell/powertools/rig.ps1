$RIG_HOME = "$HOME\.rig"

function rig { 
    # Run git command in rig mode
    git --git-dir=$RIG_HOME --work-tree=$HOME $args 
}

function rig-reset {
    # Resets the current branch to the state of the latest commit, discarding any changes made after that commit.
	rig reset --hard HEAD
}

function rig-list {
    # List all files in the rig repository
    rig ls-tree -r HEAD --name-only
}

function rig-up {
    # Add files to the rig repository
	foreach ($arg in $args) {
    	rig add $HOME\$arg
		echo "Added $arg"
	}
	$commitMessage = "Modified " + ($args -join ", ")
	rig commit -m $commitMessage
	rig push
}

function rig-down {
    # Pull changes from the rig repository
	rig reset --hard HEAD
	rig pull
}

function rig-remove {
    # Remove files from the rig repository
    foreach ($arg in $args) {
        rig rm -r --cached $HOME\$arg
        echo "Removed $arg"
    }
    $commitMessage = "Removed " + ($args -join ", ")
    rig commit -m $commitMessage
    rig push
}

function rig-ignore {
    # Add files to the .gitignore file
    foreach ($arg in $args) {
        echo $arg | Out-File -Append -Encoding utf8 $HOME\.gitignore
        echo "Ignored $arg"
    }
    rig add $HOME\.gitignore
    rig commit -m "Updated .gitignore"
    rig push
}