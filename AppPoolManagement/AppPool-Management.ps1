<#
   .Notes
     Script: AppPool-Management.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>
<#[CmdletBinding()]
Param(
   [Parameter(Mandatory=$true)]
   [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
   [ValidateNotNullOrEmpty()]
   [String]$Environment,
   [ValidateSet("Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool")]
   [ValidateNotNullOrEmpty()]
   [Parameter(Mandatory=$true)]
   [String]$Operation="Get-WebAppPoolState",
   [Parameter(Mandatory=$false)]
   [ValidateSet("UserAppPool","PatientAppPool","LoanAppPool","ServiceAppPool","PremiumAppPool","BillAppPool","PaymentAppPool")]
   $appPoolName="UserAppPool"
   )#>

function  Invoke-AppPoolAction{
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
        Specify environment name.
            List of allowed environments:"Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD"
          Note: This list will be updated when customized script based on needs
    .PARAMETER Actions
        Specify action.
             List of allowed Actions:"Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool"
    .PARAMETER appPoolName
        Specify app pool name.
        List of allowed environments:"UserAppPool","PatientAppPool","LoanAppPool","ServiceAppPool","PremiumAppPool","BillAppPool","PaymentAppPool"
        Note: This list will be updated when customized script based on needs
    
    .INPUTS
     None. You cannot pipe objects 

    .OUTPUTS
      None. dont return any one value . it writes status of application pool on the host

    .EXAMPLE
        PS > Invoke-AppPoolAction -Environment Test1 

        2023-04-24 10:20:12 Status of the UserAppPool app pool is started in Test1-Web-01 server for environment -Test1
        2023-04-24 10:20:12 Status of the UserAppPool app pool is started in Test1-Web-02 server for environment -Test1

    .EXAMPLE
         PS > Invoke-AppPoolAction -Environment Test1  -appPoolName LoanAppPool

        2023-04-24 11:21:13 Status of the LoanAppPool app pool is started in Test1-Web-01 server for environment -Test1
        2023-04-24 11:21:14 Status of the LoanAppPool app pool is started in Test1-Web-02 server for environment -Test1

    .EXAMPLE
              PS > Invoke-AppPoolAction -Environment Test1  -appPoolName LoanAppPool -Action Restart-WebAppPool ChangeTransactionID Stop-WebAppPool

        2023-04-24 11:21:13 Status of the LoanAppPool app pool is stopped in Test1-Web-01 server for environment -Test1
        2023-04-24 11:21:14 Status of the LoanAppPool app pool is stopping in Test1-Web-02 server for environment -Test1

    .LINK 
        WebAdministration
    .LINK 
        Get-WebAppPoolState,Start-WebAppPool,Stop-WebAppPool,Restart-WebAppPool
    .LINK 
        Invoke-Command

     .NOTES
        Author: Rajesh Kolla
        Last Edit: 2023-04-03
        Version 1.0 - initial version
      #>
[CmdletBinding()]
Param(
      [Parameter(Mandatory=$true)]
      [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
      [ValidateNotNullOrEmpty()]
      [String]$Environment,
      [Parameter(Mandatory=$false)]
      [ValidateSet("Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool")]
      [String]$Action="Get-WebAppPoolState",
      [Parameter(Mandatory=$false)]
      [ValidateSet("UserAppPool","PatientAppPool","LoanAppPool","ServiceAppPool","PremiumAppPool","BillAppPool","PaymentAppPool")]
      [string]$AppPool="UserAppPool",
      [Parameter(Mandatory=$false,HelpMessage="Pleae enter change ticket\Incident number to apply changes on AppPool")]
      [string]$ChangeTransactionID
)
  $JobName ="AppPool_Management"
  $PSModule="D:\Programs\Jobs\PS-Modules\"

  if(!(Env:PSModulePath.Contains($PSModule))){
    $PSModulePath=$env:PSModulePath+";$PSModule"
    [Environment]::SetEnvironmentVariable("PSModulePath",$PSModulePath,"Process")
  }

  if(Get-Module PS-Utility){Remove-Module PS-Utility}
   Import-Module PS-Utility -Force

  if ($Action -ne "Get-WebAppPoolState" -and !(Test-ChangeTransactionID $ChangeTransactionID)){
    Write-Host "Please try with Valid Change ticket\Incident for changeTransactionID to perform $Action action on $AppPool." -ForegroundColor Red
  }
  
  Clear-Host
  Initialize-Logging -JobName $JobName #-ScriptPath $PSScriptRoot
  Initialize-SendEmail -JobName $JobName -Environment $Environment #-ScriptPath $PSScriptRoot

  if($ChangeTransactionID){Write-Message -Message "Performing $Action on $AppPool using $ChangeTransactionID."}
  
  [Collection.Generic.List[string]] $logs=New-Object Collections.Generic.List[string]
  
  try {
    $WebBackEndServers =Get-Servers -Environment $Environment
    $WebBackEndServers.Keys |Sort-Object |&{Process{$env=$_
    $WebBackEndServers[$env]|&{Process{
    if($Operation -eq "Restart-WebAppPool"){
      $status=  Invoke-AppPoolOperation -hostname $_ -appPoolName $AppPool -Operation Restart-WebAppPool
       Start-Sleep -Milliseconds 10
    }else{
        $status=  Invoke-AppPoolOperation -hostname $_ -appPoolName $AppPool -Operation Get-WebAppPoolState

        if($Operation -eq "Stop-WebAppPool" -and $status -ne "Stopped"){
            $status=  Invoke-AppPoolOperation -hostname $_ -appPoolName $AppPool -Operation Stop-WebAppPool
        }elseif($Operation -eq "Start-WebAppPool" -and $status -eq "Stopped"){
            $status=  Invoke-AppPoolOperation -hostname $_ -appPoolName $AppPool -Operation Start-WebAppPool
        }
      }
      $status=  Invoke-AppPoolOperation -hostname $_ -appPoolName $AppPool -Operation Get-WebAppPoolState -VerboseLog $true
        }};
    }};
    Write-Success
    $logs.Add($(Get-MessageLog))
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
     if ($Action -ne "Get-WebAppPoolState"){Send-Email -Attachments $logs}
      
  }
            
}

function Invoke-AppPoolOperation{
<# 
 .SYNOPSIS
  This is generic function and user to perform operations on AppPool remotely in remote machine
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [string] $hostname,
    [Parameter(Mandatory=$false)]
    [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
    [string]$Environment,
    [Parameter(Mandatory=$true)]
    [ValidateSet("Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool")]
    [string] $Operation,
    [Parameter(Mandatory=$true)]
    [ValidateSet("UserAppPool","PatientAppPool","LoanAppPool","ServiceAppPool","PremiumAppPool","BillAppPool","PaymentAppPool")]
    [string]$appPoolName,
    [Parameter(Mandatory=$false)]
    [bool] $VerboseLog=$false
)
    $scriptBlock=[scriptblock]::Create("Import-Module WebAdministration; $Operation -Name $appPoolName")
    $result=Invoke-Command  -ComputerName $hostname  -ScriptBlock $scriptBlock

    $status=$result.value

    if ($VerboseLog ){
        
        $message=[string]::Empty

        if($Environment){$message= "Status of the $appPoolName app pool is $status in $hostname server for environment - $Environment."}
        else {$message="Status of the $appPoolName app pool is $status in $hostname."}
        
        Write-Message -Message $message
    }
    return $status
}

#Invoke-AppPoolAction -Environment $Environment -Action $Action -AppPool $appPool

