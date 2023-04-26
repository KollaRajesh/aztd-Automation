<#
   .Notes
     Script: New-AppPoolManagementManifest.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>
function New-AppPoolManagementManifest{
    $psd1File= Join-Path $PSScriptRoot "AppPool-Management.psd1"
    $RootModule= "AppPool-Management.psm1"
    $manifest=@{

        Path =$psd1File
        RootModule=$RootModule
        Author ="Rajesh Kolla"
    }
    New-ModuleManifest @manifest
}
New-AppPoolManagementManifest