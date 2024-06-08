################################################################################
#                                                                              #
#                           PowerShell Toolbox                                 #
#                                                                              #
################################################################################

# Set local variables
$RIG_HOME = "$HOME\.rig"


# Config rig functions
function rig { 
    git --git-dir=$RIG_HOME --work-tree=$HOME $args 
}

function rig-reset {
	rig reset --hard HEAD
}

function rig-list {
    rig ls-tree -r HEAD --name-only
}

function rig-up {
	foreach ($arg in $args) {
    	rig add $HOME\$arg
		echo "Added $arg"
	}
	$commitMessage = "Modified " + ($args -join ", ")
	rig commit -m $commitMessage
	rig push
}

function rig-down {
	rig reset --hard HEAD
	rig pull
}

function rig-remove {
    foreach ($arg in $args) {
        rig rm --cached $HOME\$arg
        echo "Removed $arg"
    }
    $commitMessage = "Removed " + ($args -join ", ")
    rig commit -m $commitMessage
    rig push
}

function rig-ignore {
    foreach ($arg in $args) {
        echo $arg | Out-File -Append -Encoding utf8 $HOME\.gitignore
        echo "Ignored $arg"
    }
    rig add $HOME\.gitignore
    rig commit -m "Updated .gitignore"
    rig push
}


# Github Copilot
function suggest {
	gh copilot suggest $args
}

function explain {
	gh copilot explain $args
}