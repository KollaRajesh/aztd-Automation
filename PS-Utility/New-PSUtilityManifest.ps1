<#
   .Notes
     Script: New-PSUtilityManifest.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>
function New-PSUtilityManifest  {
    $psd1File= Join-Path $PSScriptRoot "PS-Utility.psd1"
    $RootModule= "PS-Utility.psm1"
    $manifest=@{

        Path =$psd1File
        RootModule=$RootModule
        Author ="Rajesh Kolla"
    }
    New-ModuleManifest @manifest
}
New-PSUtilityManifest