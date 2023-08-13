<#
.SYNOPSIS
 Start process after startup the machine

.DESCRIPTION
Start process after startup the machine

.PARAMETER Processes
 list of defined Processes

.EXAMPLE
 
Example 1
    Start-ProcessAtStartup

Example 2
    Start-ProcessAtStartup $Process
.NOTES
General notes
#>
function Start-ProcessAtStartup {
  [CmdletBinding()]
  param (
    [Hashtable]$Processes
  )
  
  begin {
    $FunctionName= $MyInvocation.InvocationName
    Write-Verbose -Message "$FunctionName - Start"
    #$Processes  = New-Object -TypeName Hashtable
  }
  process {
    Write-Verbose -Message "$FunctionName - processing"
    if(!$Processes){
      $Processes =@{  WT=[ordered]@{ Name ="WT"
                                     Path ="$($env:USERPROFILE)\AppData\Local\Microsoft\WindowsApps\wt.exe"
                                     Instances=1
                               }
                      PowerShell_ISE=[ordered]@{ Name ="Powershell_ISE"
                                                 Path ="C:\Windows\System32\WindowsPowerShell\v1.0\powershell_ise.exe"
                                                 Instances=1
                                                }
                      Chrome=[ordered]@{ Name ="Chrome"
                                         Path ="C:\Program Files (x86)\Google\Chrome\application\chrome.exe"
                                         Instances=1
                                       }
                      Edge=[ordered]@{ Name ="Edge"
                                       Path ="C:\Program Files (x86)\Microsoft\Edge\Application\msedge.exe"
                                       Instances=1
                                      }
                      Ssms=[ordered]@{ Name ="SSMS"
                                       Path ="C:\Program Files (x86)\Microsoft SQL Server Management Studio 18\Common7\Ssms.exe"
                                       Instances=1
                                      }
                      Code=[ordered]@{ Name ="Code"
                                       Path ="$($env:USERPROFILE)\AppData\Local\Programs\Microsoft VS Code\bin\code"
                                       StartUpPath ="$($env:USERPROFILE)\CodeRep\PS"
                                       Instances=1
                                    }
                      OneNote=[ordered]@{ Name ="OneNote"
                                          Path ="C:\Program Files (x86)\Microsoft office\root\Office16\onenote.exe"
                                          Instances=1
                                        }
                ControlUpConsole=[ordered]@{ Name ="ControlUpConsole"
                                             Path ="C:\Users\public\Desktop\ControlUpConsole.exe"
                                             Instances=1
                                           }
            }
          }

$Processes.Keys |&{Process{
                      $process=$Processes[$_]
                       if (Test-Path $process["Path"]){
                         1..$process.Instances |&{Process{ Start-Process -FilePath  "$($process["Path"])" }}
                       }
                    }
                  }

  }
  end {
        Write-Verbose -Message "$FunctionName - End"
  }
}


                    