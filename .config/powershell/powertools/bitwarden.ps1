$BW_CLIENTID = [Environment]::GetEnvironmentVariable("BW_CLIENTID", "User")
$BW_CLIENTSECRET = [Environment]::GetEnvironmentVariable("BW_CLIENTSECRET", "User")
$BW_PASSWORD = [Environment]::GetEnvironmentVariable("BW_PASSWORD", "User")

function bw-clear { 
    '' | clip
}
function bw-unlock {
    ((bw unlock --passwordenv BW_PASSWORD) -match 'env:BW_SESSION=".*"')[0].split('> ')[1] | Invoke-Expression
}
function bw-search($id) {
    bw-unlock
    bw list items --search $id --pretty
}
function bw-get($id) {
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
            write-host $username
            write-host $password
        }
        default {
            $results | jq
            write-host "Error: Multiple results found"
        }
    }
}