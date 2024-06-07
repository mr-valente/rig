################################################################################
#                                                                              #
#                          PowerShell Functions                                #
#                                                                              #
################################################################################


# Set envrioment variables
$RIG = "$HOME/.rig"
$DEV = "$HOME/.dev"


# Dotfile rigging
function rig { 
    git --git-dir=$RIG --work-tree=$HOME $args 
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

# Github Copilot
function suggest {
	gh copilot suggest $args
}

function explain {
	gh copilot explain $args
}