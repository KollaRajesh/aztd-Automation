 <#
      .NOTES
        Author: Rajesh Kolla
        Last Edit: 2023-06-01
        Version 1.0 - initial version #>

 
<#[CmdletBinding()]
Param(
        [Parameter(Mandatory=$True)]
        [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD", "PA")]
        [ValidateNotNullOrEmpty()]
        [String]
        $Environment,
        [ValidateSet("Get-Status","Start-Service" ,"Stop-Service","Restart-Service")]
        [Parameter(Mandatory=$false)]
        [string]$Action="Get-Status",
        [ValidateSet("DSL.EncryptReportService" ,"DSLOrigWinService","Workload Automation Agent")]
        [Parameter(Mandatory=$false)]
        [string]$ServiceName="DSL.EncryptReportService"
    )#>
 

    function Invoke-ServiceAction{
        <#
        
            .SYNOPSIS
                Script to perform operation on specific DSLO windows service for specific environment remotely.
        
            .DESCRIPTION
                This script is defined to simplify operations on specific DSLO Windows service  for specific environment remotely 
            
                PreRequisites:
                     1. WinRm Service should run in source server (From where triggering commands and Destination servers (on which machine applying commands)
                     2. Environtment.json will be update with correct server names and environment.
        
            .PARAMETER Environment
                Specifies environment name.
                    List of allowed environments:"SLO1","SLO2","SLO3","SLO5","SLO6","PROD", "PA"
                  Note: This list will be updated when customized script based on needs
        
            .PARAMETER Actions
                Specifies environment name.
                     List of allowed Actions:Get-ServiceStatus","Start-Service" ,"Stop-Service","Restart-Service
        
            .PARAMETER Service Name 
                Specifies app pool name.
                List of allowed environments:DSL.EncryptReportService" ,"DSLOrigWinService","Workload Automation Agent"
                Note: This list will be updated when customized script based on needs
            
            .INPUTS
             None. You cannot pipe 
        
            .OUTPUTS
                None. dont return any one value . it writes status of application pool on the host
        
            .EXAMPLE
                PS > Invoke-ServiceAction -Environment SLO1 
                
                   Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072623.txt

                   2023-06-07 04:26:24: DSL.EncryptReportService is Running in VCWD003133 server for environment - SLO1 .

                   Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072623.txt
        
            .EXAMPLE
                 PS >  Invoke-ServiceAction  -Environment SLO1  -ServiceName DSL.EncryptReportService
                 
                    Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072704.txt

                    2023-06-07 04:27:04: DSL.EncryptReportService is Running in VCWD003133 server for environment - SLO1 .

                    Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072704.txt
            
            .EXAMPLE
                 PS >  Invoke-ServiceAction  -Environment SLO1  -ServiceName DSL.EncryptReportService  -IncludedExtrenalTranscript $true

                    2023-06-07 04:33:18: DSL.EncryptReportService is Running in VCWD003133 server for environment - SLO1 .
        
            .EXAMPLE
                  PS > Invoke-ServiceAction -Environment SLO1  -ServiceName DSLOrigWinService -Action Start-Service -ChangeTransactionID CHG11655917

                  Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074730.txt

                    2023-06-07 05:47:30: Performing Start-Service action on DSLOrigWinService using CHG11655917.
                    2023-06-07 05:47:30: DSLOrigWinService is already running in VCWD003133 server for SLO1  environment.

                  Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074730.txt

                  Note: Email functionality only work in PA \PROD Server

        .EXAMPLE
                  PS > Invoke-ServiceAction -Environment SLO1  -ServiceName DSLOrigWinService -Action Stop-Service -ChangeTransactionID CHG11655917

                  Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074837.txt

                    2023-06-07 05:48:37: Performing Stop-Service action on DSLOrigWinService using CHG11655917.
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                        WARNING: Waiting for service 'DSLOrigWinService (DSLOrigWinService)' to stop...
                    2023-06-07 05:49:10: DSLOrigWinService is Stopped in VCWD003133 server for SLO1  environment.
                    
                    Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074837.txt

                    Note: Email functionality only work. if run this command from PA \PROD Server

         .EXAMPLE
                  PS > Invoke-ServiceAction -Environment SLO1  -ServiceName DSLOrigWinService -Action Stop-Service -ChangeTransactionID CHG11655917

                    Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306075130.txt

                    2023-06-07 05:51:30: Performing Restart-Service action on DSLOrigWinService using CHG11655917.
                    2023-06-07 05:51:34: DSLOrigWinService is Running in VCWD003133 server for SLO1  environment.

                    Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306075130.txt

                    Note: Email functionality only work. if run this command from PA \PROD Server

            .LINK 
                Get-Service,   Stop-Service,    Start-Service, Set-Service

        #>
        [CmdletBinding()]
        Param(

                [Parameter(Mandatory=$True)]
                [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD", "PA")]
                [String]$Environment,
                [ValidateSet("Get-ServiceStatus","Start-Service" ,"Stop-Service","Restart-Service")]
                [Parameter(Mandatory=$false)]
                [string]$Action="Get-ServiceStatus",
                [ValidateSet("DSL.EncryptReportService" ,"DSLOrigWinService","Workload Automation Agent")]
                [Parameter(Mandatory=$false)]
                [string]$ServiceName="DSL.EncryptReportService",
                [Parameter(Mandatory=$false)]
                [bool]$IncludedExtrenalTranscript=$false,
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
                Write-Verbose -Message "Processing $functionName with Action- $Action on $ServiceName windows service in $($env:ComputerName)." }
                else {Write-Verbose -Message "Processing $functionName with Action- $Action on $ServiceName windows service in $($env:ComputerName) using $ChangeTransactionID." }
                
                
                Import-PSUtilityModule

                if ([string]::IsNullOrWhiteSpace($Environment)){
                    $Environment =Get-CurrentEnvironment
                    
                    if ([string]::IsNullOrWhiteSpace($Environment)){
                        Write-Host "Please provide Environment to perform $Action action on $AppPool ." -ForegroundColor Red
                    return
                    }
                 }
                if ($Action -ne "Get-ServiceStatus" -and !(Test-ChangeTransactionID $ChangeTransactionID)){
                    Write-Host "Please try with Valid Change ticket\Incident number through ChangeTransactionID to perform $Action action on $AppPool ." -ForegroundColor Red
                    return
                }
                
                Initialize-Logging   -ScriptPath $PSScriptRoot -IncludedExtrenalTranscript $IncludedExtrenalTranscript
                Initialize-SendEmail  -Environment $Environment  -ScriptPath $PSScriptRoot
            
                if($ChangeTransactionID) {Write-Message -Message "Performing $Action action on $ServiceName using $ChangeTransactionID."}
            
                [Collections.Generic.List[String]] $logs = New-Object Collections.Generic.List[String] 
            
                try{
                    $BatchNodes= Get-BatchNodes -Environment $Environment
            
                    $BatchNodes.Keys |Sort-Object  |  &{process{ $env=$_
                        
                        $BatchNodes[$env] | &{process{ 
                            $Node=$_
                            
                            [void] (Invoke-ServiceOperation -Node $Node  -ServiceName $ServiceName -Operation $Action -Environment  $env)
                            
                        }};
                        }};
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
                         if (!$IncludedExtrenalTranscript){
                        if (Get-TranscriptRunningState){  
                            Write-Host ""
                            Stop-Transcript 
                            Write-Host ""
                            Set-TranscriptRunningState -IsRunning $false 
                          }
                       } 
                        if ($Action -ne "Get-ServiceStatus" -and $env:COMPUTERNAME.StartsWith("VCW")){ Send-Email -Attachments $logs }else {Write-Host "Note: Email functionality only work. if run this command from PA \PROD Server"  -ForegroundColor Cyan}
                }
            }
        end{
                Write-Verbose -Message "$functionName - END"
            }
        }
        
        function Invoke-ServiceOperation{
        <##
            .SYNOPSIS
                This is generic function and  used to perform  all actions on service  remotely for requested machine.
        ##>
        Param(
            [Parameter(Mandatory=$True)]
            [System.Collections.Specialized.OrderedDictionary]$Node,
            [Parameter(Mandatory=$false )]
            [string]$Environment,
            [Parameter(Mandatory=$True )]
            [ValidateSet("Get-ServiceStatus","Start-Service" ,"Stop-Service","Restart-Service")]
            [string]$Operation="Get-ServiceStatus",
            [ValidateSet("DSL.EncryptReportService" ,"DSLOrigWinService","Workload Automation Agent")]
            [Parameter(Mandatory=$True)]
            [string]$ServiceName="DSL.EncryptReportService",
            [Parameter(Mandatory=$false)]
            [bool] $VerboseLog=$True,
            [bool]$IncludedExtrenalTranscript=$false
            )
            Begin
            {
                $functionName = $MyInvocation.InvocationName
                Write-Verbose -Message "$functionName - STARTED."
                enum Status{
                    Running
                    Stopped
                    }
            }
            Process
            {   
                Write-Verbose -Message "Processing -$functionName  With values $serviceName  service name , $Operation operation, $($Node.NodeName) and  $Environment environment." 
               
                 $service=Get-Service -ComputerName $Node.NodeName -Name $serviceName 
                  $currentStatus=[string]$service.Status

                if ($service){ 
                    
                    if($Operation -eq "Stop-Service" ){
                         if($service.Status -eq [string]([Status]::Running)){
                            Set-Service  -name $service.Name -StartupType  Manual  -ComputerName $service.MachineName -Status Stopped ;
                            $service.WaitForStatus([string]([Status]::Stopped))
                            $currentStatus= [string]([Status]::Stopped)

                         }else {$currentStatus= "already stopped"}
                    
                    }elseif ($Operation -eq "Start-Service" ){
                        if ($node.IsActive -eq $true ){
                            if  ($service.Status -eq [string]([Status]::Stopped)){
                                    Set-Service  -name $service.Name -StartupType   Automatic   -ComputerName $service.MachineName -Status Running
                                    $service.WaitForStatus([string]([Status]::Running))
                                    $currentStatus= [string]([Status]::Running)
                            }else {$currentStatus= "already running"}
                        }
                    }elseif($service.Status -eq [string]([Status]::Stopped) -and ($Operation -eq "Restart-Service" )  ){
                                Set-Service  -name $service.Name -StartupType  Automatic  -ComputerName $service.MachineName -Status Running;
                                $service.WaitForStatus([string]([Status]::Running))
                                $currentStatus= [string]([Status]::Running)
                    } elseif(($service.Status -eq [string]([Status]::Running))-and ($Operation -eq "Restart-Service" )  ){
                                Set-Service  -name $service.Name -StartupType  Manual  -ComputerName $service.MachineName -Status Stopped ;
                                $service.WaitForStatus([string]([Status]::Stopped))
                                Set-Service  -name $service.Name -StartupType  Automatic  -ComputerName $service.MachineName -Status Running;
                                $service.WaitForStatus([string]([Status]::Running))
                               $currentStatus= [string]([Status]::Running)
                    }

              }
                if ($VerboseLog){
                    $message= [string]::Empty
                    if ($Environment){$message= "$serviceName is $currentStatus in $($Node.NodeName) server for $Environment  environment."
                        }  else{$message="$serviceName is $currentStatus in $($Node.NodeName) server."}                     
                    Write-Message -Message $message -IncludedExtrenalTranscript $IncludedExtrenalTranscript
                }
            }
            end{
                Write-Verbose -Message "$functionName - END."
                return $currentStatus
            }
                    
        }


function Import-PSUtilityModule{
<#
.SYNOPSIS
Import PSUtility Module 

.DESCRIPTION
Import PSUtility Module . if it is already imported , remove module and import module 
#>
        Write-Verbose -Message "Importing PS-Utility Module -Started."
        Remove-Module PS-Utility -ErrorAction SilentlyContinue  -WarningAction SilentlyContinue
        $module=Get-Module PS-Utility -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        if ($null -eq $module)  {
                Import-Module  PS-Utility -Force
        }
        Write-Verbose -Message "Importing PS-Utility Module -End."
}

<#$Action="Start-Service"
$ChangeTransactionID=
$Environment="SLO1"
$ServiceName="DSL.EncryptReportService"
##Invoke-ServiceAction -Environment SLO1 -Action Get-ServiceStatus -ServiceName  DSL.EncryptReportService -IncludedExtrenalTranscript 

Invoke-ServiceAction -Environment $Environment  -ServiceName $ServiceName -Action $Action -ChangeTransactionID ChangeTransactionID  #> 