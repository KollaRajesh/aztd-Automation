<#
   .Notes
     Script: PS-Logging.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>


function Write-Message {
  <#
.SYNOPSIS
 Write message on host and log in message log file which was provided 

.PARAMETER Message
Message to write\log

.PARAMETER MessageLogFile
Log file location to log messages.

.EXAMPLE
Write-Message -m "log message"

.EXAMPLE
Write-Message -m "log message" -MsgLogFile "D:\logs\MsgLog\AppPool-Management-20230424.txt"

#>
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty]
    [Alias("M","Msg")]
    [string] $Message,
    [Alias("MsgLogFile")]
    [string]$MessageLogFile
  )
  begin{
    
  $Message ="$(Get-Date -Format "yyyy-MM-dd hh:mm:ss"): $Message"
  
  if ([string]::IsNullOrWhiteSpace($MessageLogFile)){
      if ([string]::IsNullOrWhiteSpace($msgLog)){ throw [CustomException]::New("Initialize Logging functionality.","")
       break;}
       $MessageLogFile=$msgLog
    }
  }
  process {
    Write-Host $Message
    $Message |Out-File $MessageLogFile -Append -Encoding ascii -Force
  }
}


function Write-Exception {
  <#
.SYNOPSIS
 Write exception message on host and log in error log file which was provided 

.PARAMETER Message
Message to write\log

.PARAMETER MessageLogFile
Log file location to log messages.

.EXAMPLE
Write-Message -m "log message"

.EXAMPLE
Write-Message -m "log message" -MsgLogFile "D:\logs\MsgLog\AppPool-Management-20230424.txt"

#>
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty]
    [Alias("ExceptionMsg","Error")]
    [System.Management.Automation.ErrorRecord] $errorRecord,
    [Alias("MsgLogFile")]
    [string]$ErrorLogFile
  )
  begin{
  if ([string]::IsNullOrWhiteSpace($ErrorLogFile)){
      if ([string]::IsNullOrWhiteSpace($errorLog)){ throw [CustomException]::New("Initialize Logging functionality.","")
       break;}
       $ErrorLogFile=$errorLog
    }
    $errorMessages=[System.Text.StringBuilder]::new()
    [void]$errorMessages.Append("$(Get-Date -Format "yyyy-MM-dd hh:mm:ss"): Error Message:"+$errorRecord.Exception.Message)
    [void]$errorMessages.Append("`nError in Line:"+$errorRecord.InvocationInfo.Line)
    [void]$errorMessages.Append("`nError in Line Number:"+$errorRecord.InvocationInfo.ScriptLineNumber)
    [void]$errorMessages.Append("`nError in Item Name:"+$errorRecord.Exception.ItemName)
    [void]$errorMessages.Append("`nException stacktrace:"+$errorRecord.ScriptStackTrace)
    $errorMessage =[string]($errorMessages.ToString())
  }
  process {
    
    if(($null -ne $ErrorLogFile ) -and (Test-Path $ErrorLogFile)){
      $errorMessage |Out-File $ErrorLogFile -Append -Encoding ascii -Force
    }
    Write-Host $errorMessage -BackgroundColor DarkRed
  }
  end{
      $errorMessages.Clear()
      $error.Clear()
  }
}

function Write-Success {
<#
.SYNOPSIS
  Write Success message to batch log file which is provided 

.PARAMETER BatchLogfile
 Batch Log file to write batch logs

.EXAMPLE
 Write-Success 

.EXAMPLE
 Write-Success -btchLogFile "D:\Logs\BatchLogs\AppPool-Management.log"
#>
  [CmdletBinding()]
  param (
    [parameter(Mandatory=$false,HelpMessage="Provide Batchlog file location")]
    [Alias("btchLogFile")]
    [string]$BatchLogfile
  )
  begin {
       if ([string]::IsNullOrWhiteSpace($BatchLogfile)){
         if ([string]::IsNullOrWhiteSpace($batchLog)){ throw [CustomException]::new("Initialize Logging functionality","") 
         Break}
         $BatchLogfile=$batchLog
       }
  }
  
  process {
    "SUCCESS" |Out-File $BatchLogfile -Encoding ascii -Force
  }
  end {
    
  }
}

function Write-Failure {
  <#
  .SYNOPSIS
    Write Failure message to batch log file which is provided 
  
  .PARAMETER BatchLogfile
   Batch Log file to write batch logs
  
  .EXAMPLE
   Write-Failure 
  
  .EXAMPLE
   Write-Failure -btchLogFile "D:\Logs\BatchLogs\AppPool-Management.log"
  #>
    [CmdletBinding()]
    param (
      [parameter(Mandatory=$false,HelpMessage="Provide Batchlog file location")]
      [Alias("btchLogFile")]
      [string]$BatchLogfile
    )
    begin {
         if ([string]::IsNullOrWhiteSpace($BatchLogfile)){
           if ([string]::IsNullOrWhiteSpace($batchLog)){ throw [CustomException]::new("Initialize Logging functionality","") 
           Break}
           $BatchLogfile=$batchLog
         }
    }
    
    process {
      "FAILURE" |Out-File $BatchLogfile -Encoding ascii -Force
    }
    end {
      
    }
  }

  
  function Initialize-Logging {
    [CmdletBinding()]
  <#
  .SYNOPSIS
   Intialize logging functionality \Infrastructure
  
  .PARAMETER JobName
  JobName
  
  .PARAMETER ScriptPath
  ScriptPath for Application where Application configuration file is located
  
  .EXAMPLE
   Initialize-Logging -JobName "AppPool-Management"
  #>
    param (
      [Parameter(Mandatory=$true)]
      [ValidateNotNullOrEmpty()]
      [string]$JobName,
      [Parameter(Mandatory=$false)]
      [string]$ScriptPath
    )
    process {
       $ConfigValues=Get-ConfigValues -ScriptPath $ScriptPath
       $datetime=Get-Date -Format "yyyyMMddmmss"
       $BatchLogPath =New-ItemIfNotExists $(Join-Path $ConfigValues.BatchMonitorPath "BatchLog") -ItemType Directory
       $msgLogPath =New-ItemIfNotExists $(Join-Path $ConfigValues.BatchMonitorPath "MsgLog") -ItemType Directory
       $errorLogPath =New-ItemIfNotExists $(Join-Path $ConfigValues.BatchMonitorPath "ErrorLog") -ItemType Directory

       New-Variable -Name batchLog -Value $(Join-Path $BatchLogPath "$JobName.txt") -Scope Script -Force
       New-Variable -Name msgLog -Value $(Join-Path $msgLogPath "$JobName-$datetime.txt") -Scope Script -Force
       New-Variable -Name errorLog -Value $(Join-Path $errorLogPath "$JobName.txt") -Scope Script -Force

       if(Test-Path $errorLog){
         Clear-Content -Path $errorLog -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
       }
       Start-Transcript -Path $msgLog -Append
       New-Variable -Name TranScriptRunning -Value $? -Scope Script -Force
    }
  }

 function Get-TranscriptRunningState {
 <#
  .SYNOPSIS
  Get Transcript Running State
  
  #>
    return $TranScriptRunning
}

function Set-TranscriptRunningState {
  <#
   .SYNOPSIS
   Set Transcript Running State
   
   #>
   param(
    [bool]$IsRunning
   )
     $TranScriptRunning =$IsRunning
 }

 function Get-MessageLog {
  <#
   .SYNOPSIS
   Get Message log file
   
   #>
     return $msgLog
 }

 function Get-ErrorLog {
  <#
   .SYNOPSIS
   Get Error log file
   
   #>
     return $errorLog
 }