<# 

    .NOTES
        Script:PS-Logging.ps1
        Version :1.0 - initial version
        Author: Rajesh Kolla
        Last Edit: 2023-04-23
 #>

 function Write-Message{
    <#
        .SYNOPSIS
        Write message on host and log in message log if specify message log
    
        .PARAMETER Message
        Message to write
        
        .PARAMETER messagLog
        message log file where to write messages
    
        .EXAMPLE
        Write-Message -Message "Log message"
    
        .NOTES
        General notes
    #>
        
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [Alias("M","Msg")]
        [String]$Message ,
        [Alias("MsgLogFile")]
        [string]$MessagLogFile
        ,[bool]$IncludedExtrenalTranscript
    )
    Begin
    {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"
    }
    Process{
        Write-Verbose -Message "Processing $functionName with Path:$Path and ItemType:$ItemType"
        $Message= "$(Get-Date -Format "yyyy-MM-dd hh:mm:ss"): $Message"
        
        Write-Host $Message 

        if (!$IncludedExtrenalTranscript)
        {
            if([string]::IsNullOrWhiteSpace($MessagLogFile)){ 
                    if( [string]::IsNullOrWhiteSpace($msgLog)){ throw [CustomException]::new("Initialize Logging functionality","")}
                    $MessagLogFile=$msgLog
            }

            if($MessagLogFile -and !($TranscriptRunning)) {
                $Message | Out-File $MessagLogFile -Append  -encoding ascii -Force
            }
        }
    }
    end {
            Write-Verbose -Message "$functionName - END"
    }
}
          
function Write-Error{
<#
.SYNOPSIS
    Write Error message in error log
    
#>
Param(
[Parameter(Mandatory=$true)]
[ValidateNotNullOrEmpty()]
[System.Management.Automation.ErrorRecord]$errorRecord,
[string]$ErrorLogFile
)
Begin{
    $functionName = $MyInvocation.InvocationName
    Write-Verbose -Message "$functionName - START"
}
Process{
        Write-Verbose -Message "Processing $functionName with errorRecord"
        if([string]::IsNullOrWhiteSpace($ErrorLogFile)){ 
                if( [string]::IsNullOrWhiteSpace($errorLog)){ throw [CustomException]::new("Initialize Logging functionality.","")}
                $ErrorLogFile=$errorLog
        }
        $errorMessages = [System.Text.StringBuilder]::new()
        [void]$errorMessages.Append("$(Get-Date -Format "yyyy-MM-dd hh:mm:ss"): Error Message: "+ $errorRecord.Exception.Message)
        [void]$errorMessages.Append("`nError in Line: "+ $errorRecord.InvocationInfo.Line)
        [void]$errorMessages.Append("`nError in Line Number: "+ $errorRecord.InvocationInfo.ScriptLineNumber)
        [void]$errorMessages.Append("`nError Item Name: "+$errorRecord.Exception.ItemName)
        [void]$errorMessages.Append("`nException StackTrace: "+$errorRecord.ScriptStackTrace)
    
        $errorMessage=[string]($errorMessages.ToString() )
        
            if($ErrorLogFile){
                $errorMessage | Out-File $ErrorLogFile -encoding ascii -Force
            }
        Write-Host $errorMessage -BackgroundColor DarkRed
        $Error.Clear()
    }
end {
      Write-Verbose -Message "$functionName - END"
    }
}
        
function Write-Success{
<#
    .SYNOPSIS
        Write Success to Batchlog
    
    .PARAMETER BatchLogFile
    BatchLogFile to specify explicitly 
    
#>
Param(
    [Alias("btchLogFile")]
    [string]$BatchLogFile
)
Begin{
    $functionName = $MyInvocation.InvocationName
    Write-Verbose -Message "$functionName - START"
}
Process{
        if([string]::IsNullOrWhiteSpace($BatchLogFile)){ 
                if( [string]::IsNullOrWhiteSpace($batchLog)){ throw [CustomException]::new("Initialize Logging functionality.","")}
                $BatchLogFile=$batchLog
       }
       "SUCCESS" | Out-File $BatchLogFile -Encoding ascii -Force
}
end {
        Write-Verbose -Message "$functionName - END"
   }
}
function Write-Failure{
<#
    .SYNOPSIS
        Write Failute to Batchlog
    
    .PARAMETER BatchLogFile
    BatchLogFile to specify explicitly 
    
#>
Param(
    [Alias("btchLogFile")]
    [string]$BatchLogFile
)
Begin{
    $functionName = $MyInvocation.InvocationName
    Write-Verbose -Message "$functionName - START"
}
Process{
    Write-Verbose -Message "Processing $functionName "
    if([string]::IsNullOrWhiteSpace($BatchLogFile)){ 
            if( [string]::IsNullOrWhiteSpace($batchLog)){ throw [CustomException]::new("Initialize Logging functionality.","")}
            $BatchLogFile=$batchLog
    }

    "FAILURE" | Out-File $BatchLogFile -Encoding ascii -Force
}
end {
    Write-Verbose -Message "$functionName - END"
}
}
      
function Initialize-Logging {
    <#
        .SYNOPSIS
            Initialize Logging functionality
        
        .PARAMETER JobName
        JobName\Script Name to Initialize Logging 
        
    #>
Param(
    [Parameter(Mandatory=$false)]
        [string]$ScriptPath,
        [bool]$IncludedExtrenalTranscript
    )
Begin{
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"
  }
Process{
    Write-Verbose -Message "Processing $functionName  "
        $ConfigValues= Get-ConfigValues -ScriptPath $ScriptPath
           
        $date=Get-Date -Format "yyyyMMddmmss"
        
        $BatchMonitorPath= $ConfigValues["BatchMonitorPath"]
        $JobName=$ConfigValues["JobName"]

        $BatchLogPath=New-ItemIfNotExists  $(Join-path $BatchMonitorPath "BatchLog") -ItemType Directory
        $msgLogPath=New-ItemIfNotExists $(Join-path $BatchMonitorPath "MsgLog") -ItemType Directory
        $errorLogPath=New-ItemIfNotExists $(Join-path $BatchMonitorPath "ErrorLog") -ItemType Directory
          
        New-Variable -Name batchLog -Value $(Join-Path $BatchLogPath "$JobName.txt") -Scope Script -Force
        New-Variable -Name msgLog   -Value $(Join-Path $msgLogPath "$JobName-$date.txt")  -Scope Script -Force
        New-Variable -Name errorLog -Value $(Join-Path $errorLogPath "$JobName.txt")  -Scope Script -Force
        
        if(Test-Path $errorLog){
            Clear-Content -Path $errorLog -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
        }
        Write-Host ""
        
        if (!$IncludedExtrenalTranscript){Start-Transcript -path $msgLog -Append
            New-Variable -Name TranscriptRunning -Value $?  -Scope Script -Force
        }else {New-Variable -Name TranscriptRunning -Value $false -Scope Script -Force}
        Write-Host ""
                
    }
end {
        Write-Verbose -Message "$functionName - END"
   }
}
    
    function Get-TranscriptRunningState{
    <#
        .SYNOPSIS
        Get Transcript Running State
    
        .EXAMPLE
        Get-TranscriptRunningState
    
    #>
     return $TranscriptRunning
    }
    
    function Set-TranscriptRunningState{
    <#
        .SYNOPSIS
        Get Transcript Running State
    
        .EXAMPLE
        Get-TranscriptRunningState
    
    #>
    Param(
      [bool]$IsRunning
      )
     $TranscriptRunning=$IsRunning
    }
          
    function Get-MessageLog{
    <#
        .SYNOPSIS
        Get message log location
    
        .EXAMPLE
        Get-MessageLog
    
    #>
    return $msgLog
    }
        
    function Get-ErrorLog{
    <#
    .SYNOPSIS
    Get Error log location
    
    .EXAMPLE
    Get-ErrorLog
    
    #>
          return $errorLog
        }