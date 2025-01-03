function Reload {
    Clear-Host
    cd $HOME
    . $PROFILE
}

function Clear-Clip { 
    '' | clip
}

function Command-Exists {
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