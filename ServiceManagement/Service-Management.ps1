 <#
      .NOTES
        Author: Rajesh Kolla
        Last Edit: 2023-06-01
        Version 1.0 - initial version #>

 
<#[CmdletBinding()]
Param(
        [Parameter(Mandatory=$False)]
        [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD", "QA")]
        [String]
        $Environment,
        [ValidateSet("Get-Status","Start-Service" ,"Stop-Service","Restart-Service")]
        [Parameter(Mandatory=$false)]
        [string]$Action="Get-Status",
        [ValidateSet("ReportService" ,"WinService","Agent Service")]
        [Parameter(Mandatory=$false)]
        [string]$ServiceName="ReportService"
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
                    List of allowed environments:"TEST1","TEST2","TEST3","TEST5","TEST6","PROD", "PA"
                  Note: This list will be updated when customized script based on needs
        
            .PARAMETER Actions
                Specifies environment name.
                     List of allowed Actions:Get-ServiceStatus","Start-Service" ,"Stop-Service","Restart-Service
        
            .PARAMETER Service Name 
                Specifies app pool name.
                List of allowed environments:ReportService" ,"WinService","Agent Service"
                Note: This list will be updated when customized script based on needs
            
            .INPUTS
             None. You cannot pipe 
        
            .OUTPUTS
                None. dont return any one value . it writes status of application pool on the host
        
            .EXAMPLE
                PS > Invoke-ServiceAction -Environment TEST1 
                
                   Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072623.txt

                   2023-06-07 04:26:24: ReportService is Running in TESTServer server for environment - TEST1 .

                   Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072623.txt
        
            .EXAMPLE
                 PS >  Invoke-ServiceAction  -Environment TEST1  -ServiceName ReportService
                 
                    Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072704.txt

                    2023-06-07 04:27:04: ReportService is Running in TESTServer server for environment - TEST1 .

                    Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306072704.txt
            
            .EXAMPLE
                 PS >  Invoke-ServiceAction  -Environment TEST1  -ServiceName ReportService  -IncludedExtrenalTranscript $true

                    2023-06-07 04:33:18: ReportService is Running in TESTServer server for environment - TEST1 .
        
            .EXAMPLE
                  PS > Invoke-ServiceAction -Environment TEST1  -ServiceName WinService -Action Start-Service -ChangeTransactionID CHGTicket 

                  Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074730.txt

                    2023-06-07 05:47:30: Performing Start-Service action on WinService using CHGTicket .
                    2023-06-07 05:47:30: WinService is already running in TESTServer server for TEST1  environment.

                  Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074730.txt

                  Note: Email functionality only work in QA \PROD Server

        .EXAMPLE
                  PS > Invoke-ServiceAction -Environment TEST1  -ServiceName WinService -Action Stop-Service -ChangeTransactionID CHGTicket 

                  Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074837.txt

                    2023-06-07 05:48:37: Performing Stop-Service action on WinService using Change.
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                        WARNING: Waiting for service 'WinService (WinService)' to stop...
                    2023-06-07 05:49:10: WinService is Stopped in TESTServer server for TEST1  environment.
                    
                    Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306074837.txt

                    Note: Email functionality only work. if run this command from QA \PROD Server

         .EXAMPLE
                  PS > Invoke-ServiceAction -Environment TEST1  -ServiceName WinService -Action Stop-Service -ChangeTransactionID CHGTicket 

                    Transcript started, output file is D:\BatchMonitor\MsgLog\Service-Management-202306075130.txt

                    2023-06-07 05:51:30: Performing Restart-Service action on WinService using CHGTicket .
                    2023-06-07 05:51:34: WinService is Running in TESTServer server for TEST1  environment.

                    Transcript stopped, output file is D:\BatchMonitor\MsgLog\Service-Management-202306075130.txt

                    Note: Email functionality only work. if run this command from QA \PROD Server

            .LINK 
                Get-Service,   Stop-Service,    Start-Service, Set-Service

        #>
        [CmdletBinding()]
        Param(

                [Parameter(Mandatory=$False)]
                [ValidateSet("TEST1","TEST2","TEST3","TEST5","TEST6","PROD", "QA")]
                [String]$Environment,
                [ValidateSet("Get-ServiceStatus","Start-Service" ,"Stop-Service","Restart-Service")]
                [Parameter(Mandatory=$false)]
                [string]$Action="Get-ServiceStatus",
                [ValidateSet("ReportService" ,"WinService","Agent Service")]
                [Parameter(Mandatory=$false)]
                [string]$ServiceName="ReportService",
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
                        if ($Action -ne "Get-ServiceStatus" -and $env:COMPUTERNAME.StartsWith("VCW")){ Send-Email -Attachments $logs }else {Write-Host "Note: Email functionality only work. if run this command from QA \PROD Server"  -ForegroundColor Cyan}
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
            [ValidateSet("ReportService" ,"WinService","Agent Service")]
            [Parameter(Mandatory=$True)]
            [string]$ServiceName="ReportService",
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
$Environment="TEST1"
$ServiceName="ReportService"
##Invoke-ServiceAction -Environment TEST1 -Action Get-ServiceStatus -ServiceName  ReportService -IncludedExtrenalTranscript 

Invoke-ServiceAction -Environment $Environment  -ServiceName $ServiceName -Action $Action -ChangeTransactionID ChangeTransactionID  #> 
