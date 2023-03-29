##Install-Module -Name IISAdministration
##Install-Module -Name WebAdministration
#Install-Module -Name XWebAdministration

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$true)]
   [ValidateSet("Test1","Test2","Test3","Test5","Test6","PROD_NonDR","PROD_DR","PROD")]
   [ValidateNotNullOrEmpty()]
   [String]$Environment,
   [ValidateSet("Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool")]
   [ValidateNotNullOrEmpty()]
   [Parameter(Mandatory=$true)]
   [String]$Operation,
   [Parameter(Mandatory=$false)]
   [ValidateSet("UserAppPool","PatientAppPool","LoanAppPool","ServiceAppPool","PremiumAppPool","BillAppPool","PaymentAppPool","")]
   $appPoolName=""

   )
Clear-host

$appPoolName="UserAppPool" <#Please Specify default Application pool #>

$WebBackEndServers=New-Object System.Collections.Generic.List[String];

##TODO: Need to read server configuration from JSON
$EnvWebBeServers=@{ PROD_NonDR=@("ProdWeb-01","ProdWeb-02","ProdWeb-03","ProdWeb-04","ProdWeb-05","ProdWeb-06");
                    PROD_DR=@("ProdWeb-07","ProdWeb-08","ProdWeb-09","ProdWeb-10","ProdWeb-11","ProdWeb-12");
                    Test1=@("Test1-Web-01","Test1-Web-02");
                    Test2=@("Test2-Web-01","Test2-Web-02");
                    Test3=@("Test3-Web-01","Test3-Web-02","Test3-Web-03","Test3-Web-04","Test3-Web-04","Test3-Web-05");
                    Test5=@("Test5-Web-01","Test5-Web-02");
                    Test6=@("Test6-Web-01","Test6-Web-02");
                    }

if($EnvWebBeServers.ContainsKey($Environment.ToUpper())){
    $WebBackEndServers.Clear();
    $WebBackEndServers.AddRange([string[]]$EnvWebBeServers[$Environment.ToUpper()])
}elseif($Environment.ToUpper() -eq "PROD"){
    $WebBackEndServers.Clear();
    $WebBackEndServers.AddRange([string[]]$EnvWebBeServers["PROD_NonDR"])
    $WebBackEndServers.AddRange([string[]]$EnvWebBeServers["PROD_DR"])
}

## This function is used to get app pool state in hosted machine remotely.
## This function is not used now in this script as generic function is used for all actions on Apppool.
function  Get-AppPoolStatus(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

    $appPoolStatus= Invoke-Command  -ComputerName $hostname -ScriptBlock {param($apn) Import-Module WebAdministration ; Get-WebAppPoolState  -Name $apn} -Args $appPoolName
    $status =$appPoolStatus.Value
    Write-Host "Status of the $appPoolName app pool is $status in $hostname"
    return $status
}

## This function is used to start app pool  in hosted machine remotely.
## This function is not used now in this script as generic function is used for all actions on Apppool.
function  Start-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

    Invoke-Command  -ComputerName $hostname  -ScriptBlock{param($apn) Import-Module WebAdministration ; Start-WebAppPool  -Name $apn} -Args $appPoolName
    
}

## This function is used to stop app pool in hosted machine remotely.
## This function is not used now in this script as generic function is defined to perform all actions on Apppool.
function  Stop-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

    Invoke-Command  -ComputerName $hostname -ScriptBlock {param($apn) Import-Module WebAdministration ; Stop-WebAppPool  -Name $apn} -Args $appPoolName
}

## This function is used to restart app pool  in hosted machine remotely.
## This function is not used now in this script as generic function is defined to perform all actions on Apppool.
function  Restart-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

    Invoke-Command  -ComputerName $hostname -ScriptBlock{param($apn) Import-Module WebAdministration ; Restart-WebAppPool  -Name $apn} -Args $appPoolName
}


## This is generic function and  used to perform  all actions on Apppool remotely in remote hosted machine.
function  Invoke-AppPoolAction(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname,
            [Parameter(Mandatory=$true)]
            [ValidateSet("Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool")]
            [string] $Action,
            [Parameter(Mandatory=$false)]
            [bool] $VerboseOn=$false
            )

    $cmd="Import-Module WebAdministration; $Operation -Name $appPoolName"
    $scriptBlock=[scriptblock]::Create($cmd)
    Invoke-Command  -ComputerName $hostname  -ScriptBlock $scriptBlock

    $status=$result.value

    if ($VerboseOn ){
     Write-Host "Status of the $appPoolName app pool is $status in $hostname server."
    }
    return $status
}

$WebBackEndServers | &{Process{
    
    if($Operation -eq "Restart-WebAppPool"){
        Invoke-AppPoolAction -hostname $_  -Action Restart-WebAppPool
    }else{
        $status=Invoke-AppPoolAction -hostname $_  -Action Get-WebAppPoolState

        if($Operation -eq "Stop-WebAppPool" -and $status -ne "Stopped"){
            Invoke-AppPoolAction -hostname $_  -Action Stop-WebAppPool
        }elseif($Operation -eq "Start-WebAppPool" -and $status -eq "Stopped"){
            Invoke-AppPoolAction -hostname $_  -Action Start-WebAppPool
        }
        $status=Invoke-AppPoolAction -hostname $_  -Action Get-WebAppPoolState
    }
}};