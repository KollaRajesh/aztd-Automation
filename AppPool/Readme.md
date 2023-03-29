---
`Script`:AppPool.ps1
`Date`: 03-28-2023
`Description`: This script used to make actions on App pool.
---
## How to perform Actions on AppPool across all servers for specific (or) set of environment(s).

We can run set of command on specific host machine remotly using  Invoke-Command

```
Invoke-Command  -ComputerName $hostname -ScriptBlock {param($apn) Import-Module WebAdministration ; Get-WebAppPoolState $apn} -Args $appPoolName
```

 >  **pre-requisites** for Invoke-Command are 
 - **WinRM service** should be running state in both host machine (where triggering commands ) and remote host machine (where executing commands)
 - **5985(for http)\5986 (https)** port should be opened between host machine and remote machine.

 > We can check WinRm Service is running or not usign below command

 ```powershell
Get-Service |Where-Object{$_.Name -eq "WinRm" -and $_.Status -eq "Running"}
 ```

> We can check WinRm port is opened between two servers 

 ```powershell
 TNC <Remote-Server> -CommonTCPPort WINRM
 ```

-  IISAdministration module is newer version of Administration module. This module cmdlets will provide better support for the pipeline and scale better.

- WebAdministration is legacy version of IIS Administration module , this module cmdlets contains more efficient code.

- If it is web server , `IIS Management services`,`IIS Management scripts and Tools` features are enabled under `Web mangement Tools`section in 'Windows Features` (Appwiz.cpl)
   > we can install IISAdministration IISAdministration PowerShell Module from the PowerShell Gallery

   ```powershell
   Install-Module IISAdministration
   Install-Module WebAdministration ##Legacy version
   ```

#### App pool commands 
1. `Get-WebAppPoolState` cmdlet used to get state of the app pool whether App pool is Started or stopped or Starting or Stopping

```powershell
function  Get-AppPoolStatus(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            $appPoolName)

    Import-Module WebAdministration ;
    $appPoolStatus=Get-WebAppPoolState -Name $appPoolName
    
    $status =$appPoolStatus.Value
    Write-Host "Status of the $appPoolName app pool is $status in $hostname"
    return $status
}

$appPoolName="UserAppPool"

$status =Get-AppPoolStatus -HostName "WebServer-01"  -appPoolName $appPoolName

```

2. `Start-WebAppPool` cmdlet is used to start particular app pool
  > Note: It will throw execption if App pool doesn't exist or App pool is already started.

```powershell
function  Start-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            $appPoolName)

    Import-Module WebAdministration ;
    Start-WebAppPool -Name $appPoolName
    return $status
}

$appPoolName="UserAppPool"
$status =Start-AppPool -HostName "WebServer-01"  -appPoolName $appPoolName
```


3. `Stop-WebAppPool` cmdlet is used to stop particular app pool
  > Note: It will throw execption if App pool doesn't exist or App pool is already stopped.

```powershell
function  Stop-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            $appPoolName)

    Import-Module WebAdministration ;
    Stop-WebAppPool -Name $appPoolName
 }

$appPoolName="UserAppPool"
$status =Start-AppPool -HostName "WebServer-01"  -appPoolName $appPoolName
```

4. `Restart-WebAppPool` cmdlet is used to stop particular app pool
  > Note: It will throw execption if App pool doesn't exist or App pool is already stopped.

```powershell
function  Restart-AppPool(){
    [CmdletBinding()]
            Param(
            [Parameter(Mandatory=$true)]
            $appPoolName)

    Import-Module WebAdministration ;
    Restart-WebAppPool -Name $appPoolName
 }

$appPoolName="UserAppPool"
$status =Start-AppPool -HostName "WebServer-01"  -appPoolName $appPoolName
```

   > Note: How to convert string to script block

```powershell
        $cmd="Import-Module WebAdministration; $Operation -Name $appPoolName"
        $scriptBlock=[scriptblock]::Create($cmd)
```

Here is the [complete script ](../AppPool/AppPool.ps1) to make actions on specific App pool in specific machine remotely.



