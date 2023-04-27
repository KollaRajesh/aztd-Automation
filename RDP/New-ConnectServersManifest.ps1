<#
   .Notes
     Script: New-ConnectServersManifest.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>
function New-ConnectServersManifest{
    $ScriptName=$(Get-Childitem . -filter "*.psm1"|  select-object  BaseName).BaseName
    $ManifestFileName= Join-Path $PSScriptRoot "$ScriptName.psd1"
    $RootModule= "$ScriptName.psm1"
    $manifest=@{
        Path =$ManifestFileName
        RootModule=$RootModule
        Author ="Rajesh Kolla"
        ModuleVersion = "1.0.0"
    }
    New-ModuleManifest @manifest
}
New-ConnectServersManifest