function Set-DNS {
    <#
    .SYNOPSIS
    Set the DNS

    .DESCRIPTION
    Finds all network adapters, and sets the DNS

    .PARAMETER Primary
    .PARAMETER Secondary

    .EXAMPLE
    Set-DNS
    Sets DNS on all nics to the loopback

    .EXAMPLE
    Set-DNS -Primary 8.8.8.8 -Secondary 8.8.4.4
    Sets DNS on all nics to google dns

    #>
    [CmdletBinding()]
    param (
        $Primary = "127.0.0.1",
        $Secondary = "127.0.0.1"
    )
    Process {
        $NetAdapter = Get-NetAdapter | Select-Object InterfaceAlias, InterfaceIndex; $NetAdapter = $NetAdapter.InterfaceIndex; ForEach($Index in $NetAdapter) {Set-DnsClientServerAddress -InterfaceIndex $Index -ServerAddresses ("$Primary","$Secondary")}
    }
    End {
        Write-Host "The IP Settings are:"
        ipconfig /all
        Write-Host "Press any key to exit"
        Read-Host
    }
}
