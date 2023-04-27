<#
   .Notes
     Script: Connect-Servers.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-26
#>
<# [CmdletBinding()]
 Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
    [String]$Environment
     )#>
    function Connect-Servers {
    <#
     .SYNOPSIS
        Connect to servrs through RDP with credentials from cmdkeys

    .DESCRIPTION
        We can connect to list of servers for environment, defined in Environments.json through RDP termininal 
        and with same credentials which will be provided by user as input.

    .EXAMPLE
     Connect-Servers -Environment $Environment

    .NOTES
        ## 1. Server host names should be replaced with actual servers in Environment.json
        ## port 3389 should open between source and destination servers
    #>

        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)]
            [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
            [String]$Environment)
        
        begin {
                 $JobName ="Connect-Servers"
                 $PSModule="D:\Programs\Jobs\PS-Modules\"

                if(!(Env:PSModulePath.Contains($PSModule))){
                $PSModulePath=$env:PSModulePath+";$PSModule"
                 [Environment]::SetEnvironmentVariable("PSModulePath",$PSModulePath,"Process")
                }

                if(Get-Module PS-Utility){Remove-Module PS-Utility}
                Import-Module PS-Utility -Force
                Clear-Host
  
                Initialize-Logging -JobName $JobName #-ScriptPath $PSScriptRoot
                Initialize-SendEmail -JobName $JobName -Environment $Environment #-ScriptPath $PSScriptRoot
        }
        
        process {
            try {
                $webBackendServers=Get-Servers -Environment $Environment
                $credentials = Get-Credential -UserName $env:UserName -Message 'Please enter password'
                $userName =$credentials.UserName
                $password =$credentials.GetNetworkCredential().Password
                $webBackendServers[$Environment] | &{Process {
                    ## Adding credentials into windows credential store  for hostname 
                    cmdkey /generic:$_ /user:$userName /pass :$password
                
                    ##If above command doesn't work then try with below command to add credentials into windows credential store  for hostname 
                    ##cmdkey /generic:TERMSRV/$_ /user:$userName /pass :$password
                    
                    ##If above two command don't work then try with below command to add credentials into windows credential store  for hostname 
                    ##cmdkey /add:$_ /user:$userName  /pass:$password
                    mstsc /v:$_ /f
                    }}
            }
            catch {
                    Write-Error -ErrorRecord $_
                    Write-Failure
                    $logs.Add($(Get-MessageLog))
                    $logs.Add($(Get-ErrorLog))
            }
            finally {
                    if(Get-TranscriptRunningState){Stop-Transcript
                        Set-TranscriptRunningState -IsRunning $false
                    }
            }
               
        }
        end {
                $cmdKeysToRemove =cmdkey  /list | &{Process {if ($_ -like "*Target=*" -and $webBackendServers[$Environment].Contains($_.Split("=")[1].Trim())){
                    $_.Split("=")[1].Trim()}}};
                    
                    $cmdKeysToRemove| &{Process {
                            
                        ## clearing credentials from  windows credential store for hostname 
                            cmdkey /delete:$_
                            
                            ##if use TERMSRV while adding credentials into windows credentials store then uncomment below line of code
                            ##cmdkey /delete:TERMSRV/$_
                        }};
                
            }
    }

#Connect-Servers -Environment $Environment