$BW_CLIENTID = [Environment]::GetEnvironmentVariable("BW_CLIENTID", "User")
$BW_CLIENTSECRET = [Environment]::GetEnvironmentVariable("BW_CLIENTSECRET", "User")
$BW_PASSWORD = [Environment]::GetEnvironmentVariable("BW_PASSWORD", "User")


function bw-unlock {
    ((bw unlock --passwordenv BW_PASSWORD) -match 'env:BW_SESSION=".*"')[0].split('> ')[1] | Invoke-Expression
}

function bw-search($id) {
    bw list items --search $id --pretty
}

function bw-get($id) {
    bw-unlock

    $results = bw-search($id)
    $count = ($results -match "object").length

    switch($count)
    {
        0 {
            write-host "Error: No results found"
        }
        1 {
            $username = bw get username $id
            $password = bw get password $id
            $password | clip
            write-host "Username: $username"
            write-host "Password copied to clipboard. Please run 'Clear-Clip' after use."
        }
        default {
            $results | ConvertFrom-Json | Format-Table
            write-host "Error: Multiple results found"
        }
    }
}