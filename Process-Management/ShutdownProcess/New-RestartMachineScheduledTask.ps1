<#
.SYNOPSIS
 Create Scheduled Task to run script at end of busines hourse for everyday .

.DESCRIPTION
Create Scheduled Task to run script at end of busines hourse for everyday .  if script is provided 
else it will Scheduled Task to run Restart-computer.ps1

.PARAMETER RestartScript
Parameter description

.EXAMPLE
An example

.NOTES
General notes
#>
function New-RunProcessTaskAtStartup {
    [CmdletBinding()]
    param (
        [string]$RestartScript
    )
    
    begin {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
    }
    
    process {
        Write-Verbose -Message "$FunctionName - processing"
            Import-Module ScheduledTasks

            if(! $RestartScript){$RestartScript =.\Start-ProcessAtStartup.ps1}
            $action =New-ScheduledTaskAction -Execute "powershell.exe" -Argument " -File ""$RestartScript"""

            $now = Get-Date
            $sixPm = New-Object DateTime($now.Year, $now.Month, $now.Day, 18, 0, 0)

            $Trigger = New-ScheduledTaskTrigger    -once -at ($sixPm)  -RepetitionInterval (New-TimeSpan -Hours 24)

            $PrincipleUser=New-ScheduledTaskPrincipal $(Join-Path $env:USERDOMAIN $env:USERNAME)

            $SettingSet=New-ScheduledTaskSettingsSet  

            $ScheuledTask = New-ScheduledTask -Action $action -Principal  $PrincipleUser -Trigger $Trigger  -Settings $SettingSet

            Register-ScheduledTask "RestartMachine" -InputObject $ScheuledTask

            Enable-ScheduledTask -TaskName "RestartMachine"
    }
    end {
        Write-Verbose -Message "$FunctionName - End"
    }
}
