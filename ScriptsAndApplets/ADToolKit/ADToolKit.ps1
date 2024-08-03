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
