<#
.SYNOPSIS
A toolkit of some common AD tasks

.DESCRIPTION
0 - Run some general health checks
1 - Pull a list of all active users in AD
2 - Pull a list of all users with administrative privileges in AD
3 - Set the password on accounts
4 - Remove the password never expires flag on accounts
5 - Set the password expires at next logon flag on accounts
6 - Disable accounts in AD
7 - Set DNS on this device
8 - Purge DNS of a specified entry
9 - Search DHCP for activity related to an IP
10 - Scan a network range for active IPs
#>

#######################
##### Functions ######
#####################
#Function to create the working directory
function Set-ProjectFolder {
    <#
    .SYNOPSIS
    Create a project folder

    .DESCRIPTION
    The default (with no parameters) is to create C:\WorkDir

    .PARAMETER baseDir
    .PARAMETER taskDir
    .PARAMETER changeDir

    .EXAMPLE
    Set-ProjectFolder
    Creates C:\WorkDir

    .EXAMPLE
    Set-ProjectFolder -taskDir "WorkWork" -changeDir
    Creates C:\WorkDir\WorkWork and changes to that directory

    .EXAMPLE
    $ProjectFolder = Set-ProjectFolder -taskDir "Work\Work"
    Creates C:\WorkDir\Work\Work and assigns the path to the variable $ProjectFolder

    .EXAMPLE
    Set-ProjectFolder -baseDir "D:\WorkDir" -changeDir
    Overides the default base directory to creates D:\WorkDir\ and changes to that directory

    #>
    [CmdletBinding()]
    param (
        [string]$baseDir = "$env:SystemDrive\WorkDir",
        [string]$taskDir,
        [switch]$changeDir
    )
    process {
        #If the path doesn't exist - Make it. 
        if (!(test-path $basedir)){
            #New-Item -Path "$baseDir" -ItemType "directory"
            mkdir "$basedir"
        }
        #Check if task dir is needed
        if (!([string]::isnullorempty($taskDir))){
            if (!(test-path "$baseDir\$taskDir")){
                #New-Item -Path "$baseDir\$taskDir" -ItemType "directory"
                mkdir "$baseDir\$taskDir"
            }
        }
    }
    end {
        #Set working dir
        if($changeDir){
            if (!([string]::isnullorempty($taskDir))){
                Set-Location "$baseDir\$taskDir"
            }
            else{
                Set-Location "$baseDir"
            }
        }
        #Return path for working dir
        if (!([string]::isnullorempty($taskDir))){
            return "$baseDir\$taskDir"
        }
        else{
            return "$baseDir"
        }
    }
}

#Function to get the domain name
function Get-DomainName {
    <#
    .SYNOPSIS
	Get the domain name of the current computer
	
	.EXAMPLE
    $DomainName = Get-DomainName
    Get the domain name, and assign it to a variable
	
    #>
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

#Function to get DHCP info
function Get-DHCPLogInfo {
    <#
    .SYNOPSIS
	DHCP log parser
	
	.DESCRIPTION
    Searches all dhcp logs for all activity related to specified IP address
	
	.PARAMETER IPAddress
		
	.EXAMPLE
    Get-DHCPLogInfo -IPAddress 10.10.32.64
    Finds all entries in the DHCP logs related to 10.10.32.64
    #>
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [string]$IPAddress
    )

    # Define the path to the DHCP log files
    $dhcpLogPath = "C:\Windows\System32\dhcp"

    # Get a list of all DHCP log files
    $dhcpLogFiles = Get-ChildItem -Path $dhcpLogPath -Filter "DhcpSrvLog-*.log"

    # Loop through each log file and search for the IP address
    foreach ($logFile in $dhcpLogFiles) {
        # Output the name of the current log file being searched
        Write-Host "Searching in file: $($logFile.Name)"
        
        # Get the content of the DHCP log file and filter for the IP address
        Get-Content $logFile.FullName | Where-Object { $_ -match $IPAddress }
    }
}

#Function to purge entry from DNS
Function Purge-DNSEntries{
    <#
    .SYNOPSIS
	Purge DNS of stale entries
	
	.DESCRIPTION
	Finds all DNS Zones. Then searches for all entries that contain the string provided and purges them.  This searches this searches Hostname and Data fields. It also removes all name servers with the string in the name.
	
	.PARAMETER PurgeThis
	
	
	.EXAMPLE
    Purge-DNSEntries -PurgeThis "DC-01"
    Finds and removes all entries containing DC-01
	
    #>
    [CmdletBinding()]
    Param
	(
		[parameter(ValueFromPipeline=$True)]
		[String]$PurgeThis
	)

    PROCESS
    {
        $DNSZones = Get-dnsServerZone

        ForEach ($Zone in $DNSZones)
        {
            $records = Get-DnsServerResourceRecord -ZoneName $Zone.ZoneName | Where-Object {
            $_.HostName -match "$PurgeThis" -or
            $_.RecordData.PtrDomainName -match "$PurgeThis" -or
            $_.RecordData.NameServer -match "$PurgeThis"
            }

            foreach ($record in $records) {
                    # Remove the resource record
                    Remove-DnsServerResourceRecord -ZoneName $zone.ZoneName -InputObject $record -Force
                    Write-Host "Removed record with Hostname: $($record.hostname) and Data: $($record.RecordData.NameServer) from zone: $($zone.ZoneName)"
                } 
        }

        Write-Host "Completed removal of all instances of $PurgeThis."
    }
}

#Function to Scan network range
function Scan-NetworkRange {

    <#
    .SYNOPSIS
	Scan a range of IP addresses for active IPs
	
	.DESCRIPTION
	Scan a range of IP addresses for active IPs
	
	.PARAMETER StartRange
    .PARAMETER EndRange
	.PARAMETER OnlyActive
    
	.EXAMPLE
    Scan-NetworkRange -StartRange "192.168.1.21" -EndRange "192.168.1.100"
    This will output active and inactive IPs within the range 192.168.1.21-100.

    .EXAMPLE
    Scan-NetworkRange -StartRange "10.1.1.1" -EndRange "10.20.255.255" -OnlyActive
    This will output only the active IPs within the absolutely massive range 10.1-20.1-255.1-255
    #>
    
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [string]$StartRange,
        
        [Parameter(Mandatory=$true)]
        [string]$EndRange,

        [switch]$OnlyActive=$false
    )

    # Convert the IP range to a sequence of numbers
    $startIP = $StartRange.Split('.').ForEach({ [int]$_ })
    $endIP = $EndRange.Split('.').ForEach({ [int]$_ })
    
    # Loop through each segment of the IP address
    for ($a = $startIP[0]; $a -le $endIP[0]; $a++) {
        for ($b = $startIP[1]; $b -le $endIP[1]; $b++) {
            for ($c = $startIP[2]; $c -le $endIP[2]; $c++) {
                for ($d = $startIP[3]; $d -le $endIP[3]; $d++) {
                    $currentIP = "$a.$b.$c.$d"
                    $ping = Test-Connection -ComputerName $currentIP -Count 1 -Quiet
                    if ($ping) {
                        try {
                            $hostEntry = [System.Net.Dns]::GetHostEntry($currentIP)
                            $hostname = $hostEntry.HostName
                        } catch {
                            $hostname = "Hostname not found"
                        }
                        if (-not $OnlyActive) {
                            Write-Host "IP: $currentIP is active. Hostname: $hostname"
                        } else {
                            Write-Host "IP: $currentIP is active. Hostname: $hostname"
                        }
                    } elseif (-not $OnlyActive) {
                        Write-Host "IP: $currentIP is inactive."
                    }
                }
                # Reset the last segment after each loop
                $startIP[3] = 0
            }
            # Reset the third segment after each loop
            $startIP[2] = 0
        }
        # Reset the second segment after each loop
        $startIP[1] = 0
    }
}


#######################
##### Formatting #####
#####################

####Set a window title and foreground color
$uiConfig = (Get-Host).UI.RawUI
$uiConfig.WindowTitle = "Active Directory Toolkit"
$uiConfig.ForegroundColor = "DarkCyan"

Write-Host ""
Write-Host "===========================================================" -ForeGroundColor Cyan
Write-Host "|                                                         |" -ForeGroundColor Cyan
Write-Host "|              Active Directory Toolkit                   |" -ForeGroundColor Cyan
Write-Host "|                                                         |" -ForeGroundColor Cyan
Write-Host "|                Written By: Colby C                      |" -ForeGroundColor Cyan
Write-Host "|                                                         |" -ForeGroundColor Cyan
Write-Host "===========================================================" -ForeGroundColor Cyan
Write-Host ""

#########################
##### Do The Thing #####
#######################

# Prompt the user to choose an option
$choice = Read-Host "Choose an option
0 - Run some general health checks
1 - Pull a list of all active users in AD
2 - Pull a list of all users with administrative privileges in AD
3 - Set the password on accounts
4 - Remove the password never expires flag on accounts
5 - Set the password expires at next logon flag on accounts
6 - Disable accounts in AD
7 - Set DNS on this device
8 - Purge DNS of a specified entry
9 - Search DHCP for activity related to an IP
10 - Scan a network range for active IPs
"

# Call the corresponding function based on the user's choice
switch ($choice) {
    0 {
        Function-1 
    }
    1 {
        Function-2
    }
    2 {
        Function-2
    }
    3 {
        Function-2
    }
    4 {
        Function-2
    }
    5 {
        Function-2
    }
    6 {
        Function-2
    }
    7 {
        Function-2
    }
    8 {
        Function-2
    }
    9 {
        Function-2
    }
    10 {
        Function-2
    }
    
    default { Write-Output "Invalid choice. Please choose an option from 0 to 10." }
}
