function Get-DeviceStatus {
    <#
    .SYNOPSIS
    Check if a device is online

    .DESCRIPTION
    Check if a device is online, and get its IP address

    .PARAMETER deviceName
    The name(s) of the device(s) to check.

    .PARAMETER OutTable
    Switch to output the result in a table format.

    .EXAMPLE
    Get-DeviceStatus -deviceName "Device1"

    .EXAMPLE
    Get-DeviceStatus -deviceName @("Device1", "Device2")

    #>
    [CmdletBinding()]
    param (
        [string[]]$deviceName,
        [switch]$NoOutTable
    )
    Process {
        $results = foreach ($name in $deviceName) {
            $pingResult = Test-Connection -ComputerName $name -Count 1 -Quiet
            if ($pingResult) {
                $ipAddress = [System.Net.Dns]::GetHostAddresses($name) | Where-Object { $_.AddressFamily -eq 'InterNetwork' }
                [PSCustomObject]@{
                    DeviceName = $name
                    Status     = "Online"
                    IPAddress  = $ipAddress.IPAddressToString
                }
            } else {
                [PSCustomObject]@{
                    DeviceName = $name
                    Status     = "Offline"
                    IPAddress  = "N/A"
                }
            }
        }
    }
    End {
        if (!($NoOutTable)) {
            $results | Format-Table -AutoSize
        }
    }
}
