function Set-TailscaleExitNode {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true)]
        [string]$Suggestion
    )

    # Get suggestion output
    if (-not $Suggestion) {
        Write-Host "No argument supplied, getting suggestion internally..."
        $suggestion = tailscale exit-node suggest
    } else {
        $suggestion = $Suggestion
    }

    # Extract exit node id from suggestion output
    $exit_node = echo $suggestion | grep -Eo 'Suggested exit node: [^.]+' | ForEach-Object { ($_ -split ' ')[3] }

    # Check if exit node is empty
    if (-not $exit_node) {
        Write-Host "No exit node found, exiting..."
        return
    }

    # Set exit node to suggested exit node
    tailscale set --exit-node="$exit_node.mullvad.ts.net"

    # Get current date and time to log
    $current_date_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Log the exit node and the time
    Write-Host "Connected to $exit_node @ $current_date_time"
}

function Clear-TailscaleExitNode {
    [CmdletBinding()]
    param()

    # Clear exit node
    tailscale set --exit-node=""

    # Get current date and time to log
    $current_date_time = Get-Date -Format "yyyy-MM-dd HH:mm:ss"

    # Log the action
    Write-Host "Cleared exit node @ $current_date_time"
}