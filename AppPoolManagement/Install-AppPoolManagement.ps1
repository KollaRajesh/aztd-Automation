 <#
      .NOTES
        Author: Rajesh Kolla
        Last Edit: 2023-05-01
        Version 1.0 - initial version #>
        function Install-AppPoolManagement{
          Write-Verbose -Message "Importing PS-Utility Module -Started."
            
            Remove-Module PS-Utility -ErrorAction SilentlyContinue  -WarningAction SilentlyContinue
            $module=Get-Module PS-Utility -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
          if ($module) {
                    Import-Module  PS-Utility -Force
            }else {
                $InstallPSUtility=$(Join-Path $(Split-Path $PSScriptRoot  -Parent)  "PS-Utility\Install-PSUtility.PS1")
          
                . $InstallPSUtility 
             }
          Write-Verbose -Message "Importing PS-Utility Module- End."
      
          Install-DSLOPSModule  $PSScriptRoot
          
      }

      Install-AppPoolManagement

      