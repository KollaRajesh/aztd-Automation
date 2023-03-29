##Install-Module -Name IISAdministration
##Install-Module -Name WebAdministration
#Install-Module -Name XWebAdministration

[CmdletBinding()]
Param(
   [Parameter(Mandatory=$true)]
   [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD_NA","PROD_RW","RPDO")]
   [ValidateNotNullOrEmpty()]
   [String]$Environment,
   [ValidateSet("Get-WebAppPoolState","Start-WebAppPool","Stop-WebAppPool","Restart-WebAppPool")]
   [ValidateNotNullOrEmpty()]
   [Parameter(Mandatory=$true)]
   [String]$Operation,
   [Parameter(Mandatory=$true)]
   [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD_NA","PROD_RW","RPDO")]
   [ValidateNotNullOrEmpty()]
   $appPoolName=""

   )
Clear-host

$appPoolName="" <#Please Specify Application pool #>
$WebBackEndServers=New-Object System.Collections.Generic.List[String];
$EnvWebBeServers=@{ PROD_RW=@("VCWP003152","VCWP003153","VCWP003154","VCWP003159","VCWP003161","VCWP003199");
                    PROD_NA=@("VCWP003147","VCWP003148","VCWP003149","VCWP003155","VCWP003156","VCWP003157");
                    SLO1=@("VCWQ003182","VCWQ003205");
                    SLO2=@("VCWQ003179","VCWQ003180");
                    SLO3=@("VCWQ003172","VCWQ003173","VCWQ003174","VCWQ003175","VCWQ003176","VCWQ003177");
                    SLO5=@("VCWQ003168","VCWQ003169");
                    SLO6=@("VCWQ003165","VCWQ003166");
                    }


if($EnvWebBeServers.ContainsKey($Environment.ToUpper())){
  $WebBackEndServers.Clear();
  $WebBackEndServers.AddRange([string[]]$EnvWebBeServers[$Environment.ToUpper()])
}elseif($Environment.ToUpper() -eq "PROD"){
    $WebBackEndServers.Clear();
    $WebBackEndServers.AddRange([string[]]$EnvWebBeServers["PROD_NA"])
    $WebBackEndServers.AddRange([string[]]$EnvWebBeServers["PROD_RW"])
}

function  Get-AppPoolStatus(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

    $appPoolStatus= Invoke-Command  -ComputerName $hostname -ScriptBlock {param($apn) Import-Module WebAdministration ; Get-WebAppPoolState $apn} -Args $appPoolName
    $status =$appPoolStatus.Value
    Write-Host "Status of the $appPoolName app pool is $status in $hostname"
}


function  Start-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

    Invoke-Command  -ComputerName $hostname  -ScriptBlock{param($apn) Import-Module WebAdministration ; Start-WebAppPool $apn} -Args $appPoolName
    
}


function  Stop-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

            Start-AppPoolStatus-
    Invoke-Command  -ComputerName $hostname -ScriptBlock {param($apn) Import-Module WebAdministration ; Stop-WebAppPool $apn} -Args $appPoolName
}

function  Restart-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            [string] $hostname)

            Start-AppPoolStatus-
    Invoke-Command  -ComputerName $hostname -ScriptBlock{param($apn) Import-Module WebAdministration ; Restart-WebAppPool $apn} -Args $appPoolName
}


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
    }elseif($Operation -eq "Stop-WebAppPool" -and $status -ne "Stopped"){
    Invoke-AppPoolAction -hostname $_  -Action Start-WebAppPool
    }
    $status=Invoke-AppPoolAction -hostname $_  -Action Get-WebAppPoolState
}};




