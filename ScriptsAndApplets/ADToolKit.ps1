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
11 - Move FSMO roles to different server

ToDo Finish 3, 4, 5, 6
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
    Begin {
        # Define the path to the DHCP log files
        $dhcpLogPath = "$env:SystemDrive\Windows\System32\dhcp"

        # Get a list of all DHCP log files
        $dhcpLogFiles = Get-ChildItem -Path $dhcpLogPath -Filter "DhcpSrvLog-*.log"
    }
    Process {
        # Loop through each log file and search for the IP address
        foreach ($logFile in $dhcpLogFiles) {
            # Output the name of the current log file being searched
            Write-Host "Searching in file: $($logFile.Name)"
            
            # Get the content of the DHCP log file and filter for the IP address
            Get-Content $logFile.FullName | Where-Object { $_ -match $IPAddress }
        }
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
        [ValidateScript({
            if ($_ -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
                $true
            } else {
                throw "Please enter a valid IP address"
            }
        })]
        [string]$StartRange,
        
        [Parameter(Mandatory=$true)]
        [ValidateScript({
            if ($_ -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
                $true
            } else {
                throw "Please enter a valid IP address"
            }
        })]
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

#Function to Set DNS
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
        [ValidateScript({
            if ($_ -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
                $true
            } else {
                throw "Please enter a valid IP address"
            }
        })]
        $Primary = "127.0.0.1",
        [ValidateScript({
            if ($_ -match '^(?:[0-9]{1,3}\.){3}[0-9]{1,3}$') {
                $true
            } else {
                throw "Please enter a valid IP address"
            }
        })]
        $Secondary = "127.0.0.1"
    )
    Begin {
        $NetAdapter = Get-NetAdapter | Select-Object InterfaceIndex; 
        $Adapter = $NetAdapter.InterfaceIndex; 
    }
    Process {
        ForEach($Index in $Adapter) {Set-DnsClientServerAddress -InterfaceIndex $Index -ServerAddresses ("$Primary","$Secondary")}
    }
    End {
        Write-Host "The IP Settings are:"
        ipconfig /all
        Read-Host -Prompt "Press any key to exit"
    }
}

#Function to prompt the user
function Prompt-User {
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
    11 - Move FSMO roles to a different server
    99 - Exit
    "
    return $choice
}

#Function to move FSMO roles
function Move-FSMO {
    <#
    .SYNOPSIS
    Moves FSMO roles to selected computer

    .DESCRIPTION
    Moves FSMO roles to selected computer

    .PARAMETER DestDir

    .EXAMPLE
    Move-FSMO
    Moves all the FSMO roles to the computer the command is being executed on

    .EXAMPLE
    Move-FSMO -DestServer DC02
    Moves all FSMO roles to DC02
    
    .EXAMPLE
    Move-FSMO -DestServer DC02 -Force
    Seizes all FSMO roles to DC02
    #>

    [CmdletBinding()]
    Param (
    [string]$DestServer
    )
    Begin {
        if ([string]::isnullorempty($DestServer)) {
            $DestServer = hostname
        }
    }
    Process {
        Move-ADDirectoryServerOperationMasterRole -Identity $DestServer -OperationMasterRole DomainNamingMaster,InfrastructureMaster,PDCEmulator,RIDMaster,SchemaMaster
    }
}

#######################
##### Formatting #####
#####################

####Set a window title and foreground color
$uiConfig = (Get-Host).UI.RawUI
$uiConfig.WindowTitle = "Active Directory Toolkit"
$uiConfig.ForegroundColor = "Cyan"

Write-Host ""
Write-Host "===========================================================" -ForeGroundColor Green
Write-Host "|                                                         |" -ForeGroundColor Green
Write-Host "|              Active Directory Toolkit                   |" -ForeGroundColor Green
Write-Host "|                                                         |" -ForeGroundColor Green
Write-Host "|                Written By: Colby C                      |" -ForeGroundColor Green
Write-Host "|                                                         |" -ForeGroundColor Green
Write-Host "===========================================================" -ForeGroundColor Green
Write-Host ""

#########################
##### Do The Thing #####
#######################
do {
    # Prompt the user to choose an option
    $userChoice = Prompt-User

    # Call the corresponding function based on the user's choice
    switch ($userChoice) {
        #Health checks (Complete)
        0 {
            #Ask the user to use default workdir or not
            $UserSetDir = Read-Host -Prompt "Enter the path you want to use for the working directory. Leave blank to use the default C:\WorkDir\"
            if ([string]::isnullorempty($UserSetDir)){
                [string]$outputDir = Set-ProjectFolder
            }
            else {
                [string]$outputDir = Set-ProjectFolder -baseDir "$UserSetDir"
            }
            # Set some variables
            [string]$baseFilename = "HealthChecks"
            [string]$HName = $env:Computername
            [string]$DateTime = (Get-Date).ToString("MMddyy_HHmm")
            [string]$outputFile = "$outputDir\$Hname`_$baseFilename`_$DateTime.txt"

            #Generate the file
            New-Item -Path $outputFile -ItemType "file" -Force

            # Run the commands and write the output to the file
            Write-Host "Getting FSMO roles"
            Add-Content -Path $outputFile -Value "-----FSMO START-----"
            netdom query fsmo | Add-Content -Path $outputFile
            Add-Content -Path $outputFile -Value "-----FSMO END-----"

            Write-Host "Running RepAdmin /showrepl"
            Add-Content -Path $outputFile -Value "-----REPADMIN END-----"
            repadmin /showrepl | Add-Content -Path $outputFile
            Add-Content -Path $outputFile -Value "-----REPADMIN END-----"

            Write-Host "Running dcdiag /v"
            Add-Content -Path $outputFile -Value "-----DCDIAG START-----"
            dcdiag /v | Add-Content -Path $outputFile
            Add-Content -Path $outputFile -Value "-----DCDIAG END-----"

            Write-Host "Running dcdiag /test:net"
            Add-Content -Path $outputFile -Value "-----NETLOGON START-----"
            dcdiag /test:netlogons | Add-Content -Path $outputFile
            Add-Content -Path $outputFile -Value "-----NETLOGON END-----"

            # Notify the user
            Write-Host "Health check report saved to $outputFile"
        }
        #Pull users (Complete)
        1 {
            #Ask the user to use default workdir or not
            Write-Host "Enter the path you want to use for the working directory. Leave blank to use the default C:\WorkDir\"
            $UserSetDir = Read-Host
            if ([string]::isnullorempty($UserSetDir)){
                [string]$outputDir = Set-ProjectFolder
            }
            else {
                [string]$outputDir = Set-ProjectFolder -baseDir "$UserSetDir"
            }
            # Set some variables
            [string]$baseFilename = "Users"
            [string]$domainName = Get-DomainName
            [string]$DateTime = (Get-Date).ToString("MMddyy_HHmm")
            [string]$outputFile = "$outputDir\$domainName`_$baseFilename`_$DateTime.txt"
            
            #Do the thing
            Get-ADUser -Filter 'enabled -eq $true' -properties name,SamAccountName,CanonicalName,created,lastlogondate,mail,passwordlastset,passwordneverexpires,enabled | Select name,SamAccountName,CanonicalName,created,lastlogondate,mail,passwordlastset,passwordneverexpires,enabled | Export-Csv $outputFile
        }
        #Pull Admins (Complete)
        2 {
            #Ask the user to use default workdir or not
            Write-Host "Enter the path you want to use for the working directory. Leave blank to use the default C:\WorkDir\"
            $UserSetDir = Read-Host
            if ([string]::isnullorempty($UserSetDir)){
                [string]$outputDir = Set-ProjectFolder
            }
            else {
                [string]$outputDir = Set-ProjectFolder -baseDir "$UserSetDir"
            }
            # Set some variables
            [string]$baseFilename = "AdminUsers"
            [string]$domainName = Get-DomainName
            [string]$DateTime = (Get-Date).ToString("MMddyy_HHmm")
            [string]$outputFile = "$outputDir\$domainName`_$baseFilename`_$DateTime.txt"

            #Do the thing
            get-adgroupmember -Identity Administrators -Recursive | Select-Object name |foreach-object {Get-ADUser -filter "name -eq '$($_.name)'" -properties *} | select-object name,SamAccountName,CanonicalName,created,lastlogondate,mail,passwordlastset,passwordneverexpires,enabled | Export-CSV $outputFile
        }
        #Set pw (WIP)
        3 {
            Write-Host "This function is coming soon"
        }
        #Remove pw no expire (WIP)
            <#Able to set for all users. Need to build funtion to set from csv#>
        4 {
            $AllOrCsv = Read-Host "Would you like to:
            1 - Remove the password never expires flag from all users
            2 - Remove the password never expires flag from users in a csv
            "
            switch ($AllOrCsv){
                1 {
                    Get-ADUser -Filter 'Name -like "*"' -Properties DisplayName | % {Set-ADUser $_ -PasswordNeverExpires:$False}
                }
                2 {
                    Write-Host "This function is coming soon"
                }
                default {
                    Write-Host "Please enter 1 or 2"
                }
            }
        }
        #Set pw expire (WIP)
            <#Able to set for all users. Need to build funtion to set from csv#>
        5 {
            $AllOrCsv = Read-Host "Would you like to:
            1 - Set the password to expire at next logon for all users
            2 - Set the password to expire at next logon for users from a csv
            "
            switch ($AllOrCsv){
                1 {
                    Get-ADUser -Filter 'Name -like "*"' -Properties DisplayName | % {Set-ADUser $_ -ChangePasswordAtLogon:$True}
                }
                2 {
                    Write-Host "This function is coming soon"
                }
                default {
                    Write-Host "Please enter 1 or 2"
                }
            }
        }
        #Disable accounts (WIP)
        6 {
            Write-Host "This function is coming soon"
        }
        #Set DNS (Complete)
        7 {
            #Ask the user for IPs
            Write-Host "Enter the Primary IP"
            $UserPrimaryIP = Read-Host
            Write-Host "Enter the Secondary IP"
            $UserSecondaryIP = Read-Host

            #Do the thing
            Set-DNS -Primary $UserPrimaryIP -Secondary $UserSecondaryIP
        }        
        #Purge DNS (WIP - Functional)
            <#Needs some troubleshooting...
            Gets a lot of the DNS entries, but not quite all of them#>
        8 {
            #Ask the user for the item to purge
            Write-Host "Enter what you want to remove. Such as DC01.Contoso.com, or 192.168.42.42"
            $UserItemToPurge = Read-Host

            #Do the thing
            Purge-DNSEntries -PurgeThis "$UserItemToPurge"

            #Inform user
            Write-Host "Make sure to doublecheck DNS.  This seems to leave a few stragglers some times." -ForeGroundColor Red
        }
        #Search DHCP (Complete)
        9 {
            #Ask the user for the item to purge
            Write-Host "Enter IP address that you want to search for."
            $UserIpToFind = Read-Host

            #Do the thing
            Get-DHCPLogInfo -IPAddress $UserIpToFind

            Read-Host -Prompt "Press any key to continue..."
        }
        #Scan a network range (Complete)
        10 {
            #Ask the user for IPs
            Write-Host "Enter the start IP"
            $UserStartIP = Read-Host
            Write-Host "Enter the end IP"
            $UserEndIP = Read-Host

            #Do the thing
            Scan-NetworkRange -StartRange $UserStartIP -EndRange $UserEndIP -OnlyActive

            Read-Host -Prompt "Press any key to continue..."
        }
        #Move FSMO roles
        11 {
            #Ask the user to use this computer or not
            $UserSetPC = Read-Host "Enter the name of the computer to move roles to. Leave blank for this computer."
            if ([string]::isnullorempty($UserSetPC)){
                Move-FSMO
            }
            else {
                Move-FSMO -DestServer $UserSetPC
            }
        }
        
        default { Write-Output "Invalid choice. Please choose an option from 0 to 10, or 99." }
    }
} while ($userChoice -ne 99)