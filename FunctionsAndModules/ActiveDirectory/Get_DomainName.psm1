# Function to get the domain name
function Get-DomainName {
    <#
    .SYNOPSIS
	Get the domain name of the current computer
	
	.EXAMPLE
    $DomainName = Get-DomainName
    Get the domain name, and assign it to a variable
	
    #>
    [CmdletBinding()]
    Process {
        try {
            $domainName = (Get-WmiObject Win32_ComputerSystem).Domain
            if ($domainName -eq $null -or $domainName -eq '') {
                throw "Domain name not found."
            }
            return $domainName
        }
        catch {
            Write-Error "Failed to retrieve the domain name."
            return "UnknownDomain"
        }
    }
}