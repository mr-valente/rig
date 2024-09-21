################################################################################
#                                                                              #
#                           PowerShell Toolbox                                 #
#                                                                              #
################################################################################

# Set local variables
$RIG_HOME = "$HOME\.rig"


# Helper functions
function reload {
    Clear-Host
    cd $HOME
    . $PROFILE
}


# Config rig functions

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

# Github Copilot
function suggest {
	gh copilot suggest $args
}

function explain {
	gh copilot explain $args
}

# Ghostscript tools
function Merge-PDFs {
    param (
        [string]$FolderPath,     # Path to the folder containing PDF files
        [string]$OutputFile      # Path to the output PDF file
    )

    # Check if the folder exists
    if (-not (Test-Path $FolderPath)) {
        Write-Host "The specified folder does not exist." -ForegroundColor Red
        return
    }

    # Get all PDF files in the folder and sort them alphabetically
    $pdfFiles = Get-ChildItem -Path $FolderPath -Filter "*.pdf" | Sort-Object Name

    if ($pdfFiles.Count -eq 0) {
        Write-Host "No PDF files found in the specified folder." -ForegroundColor Yellow
        return
    }

    # Prepare an array of input PDF file paths
    $inputFiles = $pdfFiles | ForEach-Object { $_.FullName }

    # Check if Ghostscript is installed and accessible
    $ghostscriptPath = "gs"  # Assumes gs is in PATH. Adjust if Ghostscript isn't in PATH.
    $gsTest = Get-Command $ghostscriptPath -ErrorAction SilentlyContinue

    if (-not $gsTest) {
        Write-Host "Ghostscript is not installed or not in PATH." -ForegroundColor Red
        return
    }

    # Build the Ghostscript command
    $inputFilesString = $inputFiles -join " "
    $gsCommand = "-dBATCH -dNOPAUSE -q -sDEVICE=pdfwrite -sOutputFile=`"$OutputFile`" $inputFilesString"

    try {
        # Run the Ghostscript command
        Start-Process $ghostscriptPath -ArgumentList $gsCommand -NoNewWindow -Wait
        Write-Host "PDF merge successful. Output file: $OutputFile" -ForegroundColor Green
    } catch {
        Write-Host "Error merging PDFs: $_" -ForegroundColor Red
    }
}
