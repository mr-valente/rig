function reload {
    Clear-Host
    cd $HOME
    . $PROFILE
}

function CommandExists {
    param (
        [string]$Name
    )
    try {
        $null = Get-Command $Name -ErrorAction Stop
        return $true
    } catch {
        return $false
    }
}