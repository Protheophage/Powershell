function Set-PasswordNeverExpires {
    <#
    .SYNOPSIS
    Set AD Password Never Expires flag

    .DESCRIPTION
    Set AD Password Never Expires flag. Either remove the flag from accounts (default), or set the flag for accounts. If no CSV path is provided to -CsvName this will run on all accounts.

    .PARAMETER CsvName
    Enter the path to a csv with the list of Sam Account Names.
    The default is to title the username column SamAccountName. This can be overidden with the UserNameColumnTitle parameter.
    .PARAMETER ProjectFolder
    The default is $env:SystemDrive\WorkDir
    .PARAMETER UserNameColumnTitle
    .PARAMETER LogFileName
    .PARAMETER SetEnable
    Defualt is to disable (remove the flag). Include this switch to enable pw ever expires instead.

    .EXAMPLE
    Set-PasswordNeverExpires
    Removes the password never expires flag from all AD accounts.

    .EXAMPLE
    Set-PasswordNeverExpires -CsvName "C:\MyFolder\Users.csv"
    Removes the password never expires flag from all accounts listed in a CSV.

    .EXAMPLE
    Set-ADPasswordFromCSV -CsvName "C:\MyFolder\Users.csv" -SetEnable
    Sets the Password Never Expires flag for all accounts listed in a CSV. Useful for service accounts.

    #>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage='Enter the path to the CSV with the list of users. Such as "C:\WorkDir\Users.csv"')]
        [String]$CsvName,
        [String]$ProjectFolder = "$env:SystemDrive\WorkDir",
        [String]$UserNameColumnTitle = "SamAccountName",
        [String]$LogFileName = "PwNeverExpires.log",
        [Switch]$SetEnable
    )
    Begin {
        $UserNamesList = Import-Csv -Path $CsvName
        Import-Module ActiveDirectory
        $WorkingDir = Set-ProjectFolder -baseDir $ProjectFolder
        Start-Transcript -Path "$WorkingDir\$LogFileName" -Append
    }
    Process {
        if([string]::isnullorempty($CsvName)){
            if(!($SetEnable)){
                Write-Host "Removing Password Never Expires flag for all users."
                Get-ADUser -Filter 'Name -like "*"' -Properties DisplayName | % {Set-ADUser $_ -PasswordNeverExpires:$False}
            }
            else{
                Write-Host "Setting Password Never Expires flag for all users."
                Get-ADUser -Filter 'Name -like "*"' -Properties DisplayName | % {Set-ADUser $_ -PasswordNeverExpires:$True}
            }
        }
        else{
            if(!($SetEnable)){
                foreach ($User in $UserNamesList) {
                    $ADUser = $User.$UserNameColumnTitle
                    Write-Host "Removing Password Never Expires flag for " $ADUser
                    Set-ADUser $ADUser -PasswordNeverExpires:$False
                }
            }
            else{
                foreach ($User in $UserNamesList) {
                    $ADUser = $User.$UserNameColumnTitle
                    Write-Host "Setting Password Never Expires flag for " $ADUser
                    Set-ADUser $ADUser -PasswordNeverExpires:$True
                }
            }
        }
    }
    End {
        Stop-Transcript
        Write-Host "The log file can be found at $WorkingDir\$LogFileName"
    }
}

###############################
##### Support Functions ######
#############################
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
