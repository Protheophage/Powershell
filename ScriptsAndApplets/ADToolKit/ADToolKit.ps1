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

# Function to get the domain name
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


function Function-1 {
    Write-Output "Function 1 called"
}

function Function-2 {
    Write-Output "Function 2 called"
}

function Function-3 {
    Write-Output "Function 3 called"
}

function Function-4 {
    Write-Output "Function 4 called"
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
1
2
3
4
"

# Call the corresponding function based on the user's choice
switch ($choice) {
    1 { Function-1 }
    2 { Function-2 }
    3 { Function-3 }
    4 { Function-4 }
    default { Write-Output "Invalid choice. Please choose 1, 2, 3, or 4." }
}
