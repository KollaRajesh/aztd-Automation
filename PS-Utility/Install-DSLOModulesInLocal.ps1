#Open Powershell ISE in Administrator mode to execute this script

Set-Location "$($PSScriptRoot)\.."
   [string]$EmailId = Read-Host -Prompt "Enter User EmailId"
function Set-LocalConfigValues
{
  param (
            [string]$JsonConfigPath,
            [string]$EmailId
        )

    $config=Get-Content $JsonConfigPath -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue 
    $config=$config.Replace("SBRelay@","SBRelay.Dev@")
    $config=$config.Replace("D:\\" ,"C:\\")
    $config=$config.Replace("D:\\" ,"C:\\") 
       
 
  
   $jsonObject=$config |ConvertFrom-Json

    if( $JsonObject.BatchMonitorPath -and !(Test-path $JsonObject.BatchMonitorPath) ) { New-Item -Path $JsonObject.BatchMonitorPath -ItemType Directory  -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue }
    if( $JsonObject.DSLOPSModulePath  -and !(Test-path $JsonObject.DSLOPSModulePath)) { New-Item -Path $JsonObject.DSLOPSModulePath -ItemType Directory  -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue }
    
    if($jsonObject.EMailConfig.CCRecipients) { $jsonObject.EMailConfig.CCRecipients=($env:USERNAME)}
    if($jsonObject.EMailConfig.Recipients) { $jsonObject.EMailConfig.Recipients=$emailId}

        $jsonObject | ConvertTo-Json | Out-File $JsonConfigPath
    
 ##return  $jsonObject
    
}

$AppConfig="AppConfig.json"
$PSUtilityRoot="$($PSScriptRoot)\..\PS-Utility"
$AppPoolManagementRoot="$($PSScriptRoot)\..\AppPoolManagement"
$ServiceManagementRoot="$($PSScriptRoot)\..\ServiceManagement"
$PsUtilityConfig= "$PSUtilityRoot\$AppConfig"                                              
$AppPoolManagementConfig= "$AppPoolManagementRoot\$AppConfig" 
$ServiceManagementConfig= "$ServiceManagementRoot\$AppConfig" 
Set-LocalConfigValues -JsonConfigPath $PsUtilityConfig -EmailId $EmailId
Set-LocalConfigValues -JsonConfigPath $AppPoolManagementConfig -EmailId $EmailId
Set-LocalConfigValues -JsonConfigPath $ServiceManagementConfig -EmailId $EmailId

Set-Location $PSUtilityRoot ; Invoke-Expression(".\Install-PSUtility.ps1")

Set-Location $AppPoolManagementRoot ;Invoke-Expression(".\Install-AppPoolManagement.ps1")

Set-Location $ServiceManagementRoot; Invoke-Expression(".\Install-ServiceManagement.ps1")

