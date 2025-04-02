function Get-UserLogonSessions {
    <#
    .SYNOPSIS
    Retrieves information about user logon sessions.

    .DESCRIPTION
    This function retrieves details about user logon sessions, including logon time, session type, and duration.

    .EXAMPLE
    Get-UserLogonSessions
    Retrieves all user logon sessions.
    #>
    [CmdletBinding()]
    param ()

    process {
        Get-WinEvent -LogName "Security" | Where-Object {
            $_.Id -eq 4624
        } | ForEach-Object {
            [PSCustomObject]@{
                UserName    = $_.Properties[5].Value
                LogonTime   = $_.TimeCreated
                LogonType   = $_.Properties[8].Value
                Workstation = $_.Properties[11].Value
            }
        }
    }
}
