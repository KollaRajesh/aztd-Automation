 <#
      .NOTES
        Author: Rajesh Kolla
        Last Edit: 2023-05-01
        Version 1.0 - initial version #>

        function Install-PSUtility{
            . $(Join-Path  $PSScriptRoot  "PS-Utility.ps1")
        
            Install-DSLOPSModule $PSScriptRoot
            
        }
        Install-PSUtility