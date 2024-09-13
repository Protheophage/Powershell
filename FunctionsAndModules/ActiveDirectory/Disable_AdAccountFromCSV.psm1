function Disable-AdAccountFromCSV {
    <#
    .SYNOPSIS
    Disable AD accounts listed in a CSV

    .DESCRIPTION
    Disable accounts listed by Sam Account Names in a CSV.

    .PARAMETER CsvName
    Enter the path to a csv with the list of Sam Account Names.
    The default is to title the username column SamAccountName. This can be overidden with the UserNameColumnTitle parameter.
    .PARAMETER ProjectFolder
    The default is $env:SystemDrive\WorkDir
    .PARAMETER UserNameColumnTitle
    .PARAMETER LogFileName
    Sets the length of the randomly generated password. The default is 14.

    .EXAMPLE
    Disable-AdAccountFromCSV -CsvName "C:\MyFolder\Users.csv"
    Disables all accounts listed in Users.csv under the column titled SamAccountName
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true,
        HelpMessage='Enter the path to the CSV with the list of users. Such as "C:\WorkDir\Users.csv"')]
        [String]$CsvName,
        [String]$ProjectFolder = "$env:SystemDrive\WorkDir",
        [String]$UserNameColumnTitle = "SamAccountName",
        [String]$LogFileName = "DisabledUsers.log"
    )
    Begin {
        $UserNamesList = Import-Csv -Path $CsvName
        Import-Module ActiveDirectory
        $WorkingDir = Set-ProjectFolder -baseDir $ProjectFolder
        Start-Transcript -Path "$WorkingDir\$LogFileName" -Append
    }
    Process {
        foreach ($User in $UserNamesList) {
            $ADUser = $User.$UserNameColumnTitle
            Disable-ADAccount -Identity $ADUser
            Write-Host "Disabled $ADUser"
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
