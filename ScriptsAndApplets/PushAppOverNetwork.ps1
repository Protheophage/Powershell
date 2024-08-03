##Create Credential Object
[string]$userName = '<UserName-Here>'
[string]$userPassword = '<Password-Here>'
[securestring]$secStringPassword = ConvertTo-SecureString $userPassword -AsPlainText -Force
[pscredential]$credObject = New-Object System.Management.Automation.PSCredential ($userName, $secStringPassword)

##Define install command
$AppInstallCommand = '<Installation-Command-From-App-Here>'

##Create array with all device names
$DeviceNames = @('<List>','<of>','<Device>','<Names>','<Here>')

##Push app out to each device
foreach ($Device in $DeviceNames) {
    Invoke-Command -ComputerName "$Device" -ScriptBlock { $AppInstallCommand } -credential $credObject
}

