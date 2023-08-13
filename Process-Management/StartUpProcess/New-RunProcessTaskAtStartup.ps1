<#
.SYNOPSIS
 Create Scheduled Task to run script at startup machine 

.DESCRIPTION
Create Scheduled Task to run script at startup machine  if script is provided 
else it will Scheduled Task to run  Start-ProcessAtStartup.ps1

.PARAMETER startUpScript
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function New-RunProcessTaskAtStartup {
    [CmdletBinding()]
    param (
        [string]$startUpScript
    )
    
    begin {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
    }
    
    process {
        Write-Verbose -Message "$FunctionName - processing"
            Import-Module ScheduledTasks

            if(! $script){$script =.\Start-ProcessAtStartup.ps1}

            $action =New-ScheduledTaskAction -Execute "powershell.exe" -Argument " -File ""$script"""
            #$Trigger = New-ScheduledTaskTrigger    -once -at ([datetime]::Now.AddDays(1))  -RepetitionInterval (New-TimeSpan -Days 5)
            $Trigger = New-ScheduledTaskTrigger   -AtStartup  -RandomDelay  (New-TimeSpan -Minutes 5)

            $PrincipleUser=New-ScheduledTaskPrincipal $(Join-Path $env:USERDOMAIN $env:USERNAME)

            $SettingSet=New-ScheduledTaskSettingsSet  

            $ScheuledTask = New-ScheduledTask -Action $action -Principal  $PrincipleUser -Trigger $Trigger  -Settings $SettingSet

            Register-ScheduledTask "RunProcessAtStartup" -InputObject $ScheuledTask

            Enable-ScheduledTask -TaskName "RunProcessAtStartup"

    }
    end {
        Write-Verbose -Message "$FunctionName - End"
    }
}
