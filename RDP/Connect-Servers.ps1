[CmdletBinding()]
Param(
   [Parameter(Mandatory=$true)]
   [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
   [String]$Environment
    )
#region Functions
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
    function Connect-Servers {
        [CmdletBinding()]
        param (
            [Parameter(Mandatory=$true)]
            [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
            [String]$Environment)
        
        begin {
            $webBackendServers=Get-Servers -Environment $Environment
            $credentials = Get-Credential -UserName $env:UserName -Message 'Please enter password'
            $userName =$credentials.UserName
            $password =$credentials.GetNetworkCredential().Password
        }
        
        process {
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

    <#
        .SYNOPSIS
        # Get environment servers for given envrionment
    
        .DESCRIPTION
         Read list of servers for all environments from config and return lis of servers based on given environment
    
        .PARAMETER Environment
            Environment Name 
    
        .EXAMPLE 
            Get-Servers -Environment Test1

            Key   Value                             
            ---   -----                             
            Test2 {Test2-Web-BE-01, Test2-Web-BE-02}
    
        .NOTES
            General notes
    #>
    function Get-Servers {
        [CmdletBinding()]
        Param(
            [Parameter(Mandatory=$true)]
            [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
            [String]$Environment
            )
            
        begin {
            $WebBackendServers=New-Object 'System.Collections.Generic.Dictionary[String,System.Collections.Generic.List[string]]';
            $EnvironmentsConfigFile=Join-Path $PSScriptRoot "Environments.json"
            $WebBeServersForAllEnv= Get-Content -Path $EnvironmentsConfigFile -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |ConvertFrom-Json |Convert-ToHashTable
         }
        process {
            $WebBackendServers.Clear();
            if($WebBeServersForAllEnv.ContainsKey($Environment)){
                $WebBackendServers.Add($Environment,[string[]]$WebBeServersForAllEnv[$Environment])
            }elseif($Environment.ToUpper() -eq "PROD"){
                  $WebBeServersForAllEnv.Keys |Where-Object {$_ -like "$Environment"} | &{Process{$WebBackendServers.Add($_ , [string[]]$WebBeServersForAllEnv[$_]) }};
            }
            elseif($Environment.ToUpper() -eq "QA"){
                  $WebBeServersForAllEnv.Keys |Where-Object {$_ -like "Test"} | &{Process{$WebBackendServers.Add($_ , [string[]]$WebBeServersForAllEnv[$_])}};
            }
            
        }
        end {
            return $WebBackendServers
        }
    }
    
    <#
    .SYNOPSIS
        Helper function to take a JSON string and turn it into a hashtable
    .DESCRIPTION
        The built in ConvertFrom-Json file produces as PSCustomObject that has case-insensitive keys. This means that
        if the JSON string has different keys but of the same name, e.g. 'size' and 'Size' the comversion will fail.
        Additionally to turn a PSCustomObject into a hashtable requires another function to perform the operation.

    .INPUTS
    [System.Management.Automation.PSCustomObject] , You can pipe objects to Convert-ToHashTable

    .OUTPUTS
    Hashtable

    .ExAMPLE
     PS > Get-Content -Path ".\Environments.json" -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |ConvertFrom-Json |Convert-ToHashTable

        Name                           Value                                                                                                                                                                                                     
        ----                           -----                                                                                                                                                                                                     
        PROD_NonDR                     {ProdWeb-01, ProdWeb-02, ProdWeb-03, ProdWeb-04...}                                                                                                                                                       
        Test3                          {Test3-Web-01, Test3-Web-02, Test3-Web-03, Test3-Web-04...}                                                                                                                                               
        Test2                          {Test2-Web-01, Test2-Web-02}                                                                                                                                                                              
        Test1                          {Test1-Web-01, Test1-Web-02}                                                                                                                                                                              
        Test6                          {Test6-Web-01, Test6-Web-02}                                                                                                                                                                              
        PROD_DR                        {ProdWeb-07, ProdWeb-08, ProdWeb-09, ProdWeb-10...}                                                                                                                                                       
        Test5                          {Test5-Web-01, Test5-Web-02}   

    .LINK 
        ConvertFrom-Json
    .LINK 
        Get-Content

      #>
 function  Convert-ToHashTable(){
        [CmdletBinding()]
                Param(
                [Parameter(Mandatory=$true,ValueFromPipeline=$true )]
                [psobject] $inputObj)
        begin{
            $hash = @{}     
        }
        process {
            $inputObj.psobject.properties | &{ process{$hash[$_.Name]= [string[]]$_.Value}};
        }
        end {
            return  $hash
        }
    }
#endregion
    
Connect-Servers -Environment $Environment