function Get-ValidIP {
    param(
        [string]$IPAddress
    )

    do {
        try {
            $IPAddress = Read-Host 'Enter an IP address'

            if ($IPAddress -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
                Write-Host "The IP address is $IPAddress"
                return $IPAddress
            } else {
                Write-Host "Invalid IP address. Please try again." -ForegroundColor Red
            }
        } catch {
            Write-Host "An error occurred: $_" -ForegroundColor Red
        }
    } while ($IPAddress -notmatch '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$')
}