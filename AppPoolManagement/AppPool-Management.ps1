 <#
      .NOTES
        Author: Rajesh Kolla
        Last Edit: 2023-04-03
        Version 1.0 - initial version #>

 
<#[CmdletBinding()]
Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD_NA","PROD_RW","PROD", "PA")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Environment,
        [ValidateSet("Get-WebAppPoolState","Start-WebAppPool" ,"Stop-WebAppPool","Restart-WebAppPool")]
        [Parameter(Mandatory=$false)]
        [string]$Action="Get-WebAppPoolState",
        [ValidateSet("IndividualCreditAppPool" ,"GDSLCalculatorAppPool","DSLOrigAppPool","DSLWebAPIAppPool","DSLWebServicesAppPool")]
        [Parameter(Mandatory=$false)]
        [string]$appPool="IndividualCreditAppPool"
    )#>
 

    function Invoke-AppPoolAction{
        <#
        
          .SYNOPSIS
                Script to perform operation on specific application pool over set of server farms for specific environment remotely.
        
            .DESCRIPTION
                This script is defined to simplify operations on specific application pool over set of server farms remotely for specific environment remotely 
                using cmd-lets of WebAdministration module. Applying operations on application pool for specific server remotely using Invoke-Command.
            
                PreRequisites:
                     1. WinRm Service should run in source server (From where triggering commands and Destination servers (on which machine applying commands)
                     2.5985 port should be open between source and destination server .
                     3. Environtment.json will be update with correct server names and environment.
        
            .PARAMETER Environment
                Specifies environment name.
                    List of allowed environments:"SLO1","SLO2","SLO3","SLO5","SLO6","QA","PROD_NonDR","PROD_DR","PROD"
                  Note: This list will be updated when customized script based on needs
        
            .PARAMETER Actions
                Specifies environment name.
                     List of allowed Actions:"Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool"
        
            .PARAMETER appPoolName
                Specifies app pool name.
                List of allowed environments:"UserAppPool","PatientAppPool","LoanAppPool","ServiceAppPool","PremiumAppPool","BillAppPool","PaymentAppPool"
                Note: This list will be updated when customized script based on needs
            
            .INPUTS
             None. You cannot pipe 
        
            .OUTPUTS
                Non. dont return any one value . it writes status of application pool on the host
        
            .EXAMPLE
                PS > Invoke-AppPoolAction -Environment SLO1 
                
                2023-04-23 09:40:51: Status of the IndividualCreditAppPool app pool is Started in VCWQ003182 Server for environment - SLO1.
                2023-04-23 09:40:54: Status of the IndividualCreditAppPool app pool is Started in VCWQ003205 Server for environment - SLO1.
        
            .EXAMPLE
                 PS > Invoke-AppPoolAction -Environment SLO1  -appPoolName DSLOrigAppPool
        
            .EXAMPLE
                  PS > Invoke-AppPoolAction -Environment SLO1  -appPoolName DSLWebAPIAppPool -Operation Restart-WebAppPool
        
            .LINK 
                WebAdministration
        
            .LINK 
                Get-WebAppPoolState,Start-WebAppPool,Stop-WebAppPool,Restart-WebAppPool
        
            .LINK 
                Invoke-Command
        #>
        [CmdletBinding()]
        Param(
                [Parameter(Mandatory=$True)]
                [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD_NA","PROD_RW","PROD", "PA")]
                [String]$Environment,
                [ValidateSet("Get-WebAppPoolState","Start-WebAppPool" ,"Stop-WebAppPool","Restart-WebAppPool")]
                [Parameter(Mandatory=$false)]
                [string]$Action="Get-WebAppPoolState",
                [ValidateSet("GDSLCalculatorAppPool","IndividualCreditAppPool" ,"DSLOrigAppPool","DSLWebAPIAppPool","DSLWebServicesAppPool")]
                [Parameter(Mandatory=$false)]
                [string]$AppPool="IndividualCreditAppPool",
                [boolean]$IncludedExtrenalTranscript=$false,
                [Parameter(Mandatory=$false,HelpMessage="Please enter Change Ticket\Incident for changes")]
                [string]$ChangeTransactionID
            )
            Begin
            {
                ##Clear-Host
                $functionName = $MyInvocation.InvocationName
                Write-Verbose -Message "$functionName - START"
                
            }
            Process
            { 

                 if($ChangeTransactionID){
                Write-Verbose -Message "Processing $functionName with  -Action -$Action on $AppPool AppPool in $($env:ComputerName)." }
                else {Write-Verbose -Message "Processing $functionName with  -Action -$Action on $AppPool AppPool in $($env:ComputerName) using $ChangeTransactionID." }
                
                Write-Verbose -Message "Importing PS-Utility Module -Started."
                Remove-Module PS-Utility -ErrorAction SilentlyContinue  -WarningAction SilentlyContinue
                $module=Get-Module PS-Utility -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
                if ($null -eq $module)  {
                        Import-Module  PS-Utility -Force
                }
               <#Remove
                  $InstallPSUtility=$(Join-Path $(Split-Path $PSScriptRoot  -Parent)  "PS-Utility\PS-Utility.PS1")
              
                    . $InstallPSUtility 
              
                     $PSSendEmail=$(Join-Path $(Split-Path $PSScriptRoot  -Parent)  "PS-Utility\PS-SendEmail.ps1")
                    . $PSSendEmail 
    
                      $PSLogging=$(Join-Path $(Split-Path $PSScriptRoot  -Parent)  "PS-Utility\PS-Logging.PS1")
                    . $PSLogging 
                ##>
                Write-Verbose -Message "Importing PS-Utility Module -End."
            
                if ([string]::IsNullOrWhiteSpace($Environment)){
                    $Environment =Get-CurrentEnvironment
                    if ([string]::IsNullOrWhiteSpace($Environment)){
                        Write-Host "Please provide Environment to perform $Action action on $AppPool ." -ForegroundColor Red
                    return
                    }
                 }
                 
                if ($Action -ne "Get-WebAppPoolState" -and !(Test-ChangeTransactionID $ChangeTransactionID)){
                    Write-Host "Please try with Valid Change ticket\Incident number through ChangeTransactionID to perform $Action action on $AppPool ." -ForegroundColor Red
                    return
                }
                
            
                Initialize-Logging   -ScriptPath $PSScriptRoot -IncludedExtrenalTranscript $IncludedExtrenalTranscript
                Initialize-SendEmail  -Environment $Environment  -ScriptPath $PSScriptRoot
            
                if($ChangeTransactionID) {Write-Message -Message "Performing $Action action on $AppPool using $ChangeTransactionID."}
            
                [Collections.Generic.List[String]] $logs = New-Object Collections.Generic.List[String] 
            
                try{
                    $WebBackEndServers=Get-WebBackEndNodes -Environment $Environment
            
                    $WebBackEndServers.Keys |Sort-Object  |  &{process{ $env=$_
            
                    $WebBackEndServers[$env] | &{process{ 
            
                            if ($Action -eq "Restart-WebAppPool"){
                                $status =  Invoke-AppPoolOperation -hostName  $_   -appPoolName $appPool -Operation Restart-WebAppPool
                                    Start-Sleep -Milliseconds 10
                                }else{
            
                                    $status =  Invoke-AppPoolOperation -Environment $env -hostName  $_   -appPoolName $appPool -Operation Get-WebAppPoolState
            
                                    if ($Action -eq "Stop-WebAppPool" -and $status -ne "Stopped"){
                                        $status = Invoke-AppPoolOperation  -hostName  $_  -appPoolName $appPool -Operation Stop-WebAppPool
            
                                        Start-Sleep -Milliseconds 10
            
                                    }elseif ($Action -eq "Start-WebAppPool" -and $status -eq "Stopped"){
                                    
                                            $status =Invoke-AppPoolOperation -hostName  $_ -appPoolName $appPool -Operation Start-WebAppPool
                                    }
                                }
            
                                $status= Invoke-AppPoolOperation -Environment $env -hostName  $_ -appPoolName $appPool -Operation  Get-WebAppPoolState  -VerboseLog $true    -IncludedExtrenalTranscript    $IncludedExtrenalTranscript
                                
                            }};
                        }}
                Write-Success
                $logs.Add($(Get-MessageLog))
                }
                catch { 
                    
                    Write-Error -errorRecord $_
                    Write-Failure
                    $logs.Add($(Get-MessageLog))
                    $logs.Add($(Get-ErrorLog))
                }
                finally {
                        
                        if (Get-TranscriptRunningState){  
                            Write-Host ""
                            Stop-Transcript 
                            Write-Host ""
                            Set-TranscriptRunningState -IsRunning $false 
                          }
                        
                        if ($Action -ne "Get-WebAppPoolState"){ Send-Email -Attachments $logs }
                }
        }
        end{
            Write-Verbose -Message "$functionName - END"
        }
            
        }
            
        
        function Invoke-AppPoolOperation{
        <##
            .SYNOPSIS
                This is generic function and  used to perform  all actions on Apppool remotely in remote hosted machine.
        ##>
        Param(
            [Parameter(Mandatory=$True)]
            [string]$hostName,
            [Parameter(Mandatory=$false )]
            [string]$Environment,
            [Parameter(Mandatory=$True )]
            [ValidateSet("Get-WebAppPoolState","Start-WebAppPool" ,"Stop-WebAppPool","Restart-WebAppPool")]
            [string]$Operation,
            [ValidateSet("GDSLCalculatorAppPool","IndividualCreditAppPool" ,"DSLOrigAppPool","DSLWebAPIAppPool","DSLWebServicesAppPool")]
            [Parameter(Mandatory=$True)]
            [string]$appPoolName,
            [Parameter(Mandatory=$false)]
            [bool] $VerboseLog=$false,
            [bool] $IncludedExtrenalTranscript=$false
            )
            Begin
            {
                $functionName = $MyInvocation.InvocationName
                Write-Verbose -Message "$functionName - START."
            }
            Process
            {   
                Write-Verbose -Message "Processing -$functionName  With $Environment environment, $appPoolName  app pool and $Operation operation."                  
                $scriptBlock = [scriptblock]::Create("Import-Module WebAdministration;  $Operation -Name  $appPoolName") 
                $result=invoke-command -ComputerName  $hostName  -ScriptBlock  $scriptBlock
                $status=$result.value
                if ($result -eq "Undefined"  -and !($status)){ $status ="Stopped"}
                
                if ($VerboseLog){
                    $message= [string]::Empty
                    
                    if ($Environment){  $message="Status of the $appPoolName app pool is $status in $hostName Server for environment - $Environment."
                    } else{$message="Status of the $appPoolName app pool is $status in $hostName."}
            
                    Write-Message -Message $message -IncludedExtrenalTranscript   $IncludedExtrenalTranscript
            
                }
                return $status
            }
            end{
                Write-Verbose -Message "$functionName - END."
            }
                    
        }
        
        <#$Action="Start-WebAppPool"
        $ChangeTransactionID=
        $Environment="SLO1"
        Invoke-AppPoolAction -Environment $Environment -Action $Action -AppPool $appPool  -ChangeTransactionID $ChangeTransactionID#