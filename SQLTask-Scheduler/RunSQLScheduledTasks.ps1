#*************************************************************************
#
#	Program:	RunSQLScheduledTasks.ps1
#	Author:		Rajesh Kolla
#	Date:		06/30/2021
#
#	Desc:		Powershell script works as SQL Task Scheduler  which will find list of Sql-Tasks define in SQLTaskConfig.csv fall under schedule from LastRunTime of the Task.
#*************************************************************************
$DateTimeFormat = "MM-dd-yyyy HH:mm:ss"
$JobRun = "SQLTaskScheduler"
$SqlTaskExpired = "SQL_TASK_EXPIRED"
$SqlTaskNotScheduledToRun = "SQL_TASK_NOT_SCHEDULED_TO_RUN"
$SqlTaskReadyToRun  = "SQL_TASK_READY_TO_RUN"
$SqlTaskScriptNotFound = "SQL_TASK_SCRIPT_NOT_FOUND"
$Environment=$env:Run_ENV
$RunSQLTaskSchedulerScriptsFolderName = "RunSQLScheduledTasks"
$ScriptPath = split-path -parent $MyInvocation.MyCommand.Definition
$outputFolderPath = Join-Path $ScriptPath "\Output" 
$SQLScriptsPath = "C:\SQLScripts"																					# default SQLScripts folder path.
$BackupSQLScriptsPath = Join-Path $SQLScriptsPath "\Backup\"
$BatchMonitorPath = "C:\BatchMonitor"																					# default BatchMonitor folder path. 
$SQLRunToolPath = "C:\Programs\the\SQLRunTool\SQLRunTool.exe"												    # default SQLRunTool EXE file to execute. 
$EmailDistListPath = "C:\Programs\Jobs\DistLists\$JobRun.txt"															# default email DL list path
$RunSQLTaskSchedulerScripts = Join-Path $SQLScriptsPath "\$RunSQLTaskSchedulerScriptsFolderName"				# default path for the sql scripts to run for SQLTaskScheduler
$SQLTaskSchedulerScripts = Join-Path $ScriptPath "\SQLTaskSchedulerScripts\"										# default Path where Sql Scripts are present
$BackupPath = Join-Path $SQLTaskSchedulerScripts "\Backup"															# default backup path
$CurrentBackupPath = Join-Path $BackupPath "\$($(Get-Date).ToString("yyyyMMdd_HHmmss"))"								# current backup folder path
$ConfigFilePath = Join-Path $ScriptPath "\SQLTaskConfig.csv"															# default SQLTaskConfig.csv path
$BatchLogFilePath = Join-Path $BatchMonitorPath "\BatchLog\$JobRun.log"													# default Batch-log file path
$ErrorLogFilePath = Join-Path $BatchMonitorPath "\ErrorLog\$JobRun.log"													# default Error-log file path
$MessageLogFilePath = Join-Path $BatchMonitorPath "\MsgLog\$JobRun-$($(Get-Date).ToString("yyyyMMdd_HHmmss")).log"		# default Message-log folder path
$NCronLibPath = Join-Path $ScriptPath "\ncrontab\lib\net35"																# NCronLib path
$SMTPRelay = $env:MailRelay																			                    # default SMTP relay address
$SendFromAddress = $env:SendFromAddress																                    # default send from email address
$Recipients = New-Object Collections.Generic.HashSet[String];
$ScriptsFound = New-Object Collections.Generic.HashSet[String];
$ScriptsNotFound = New-Object Collections.Generic.HashSet[String];														
Add-Type -Path "$NCronLibPath\NCronTab.dll"
$SQLTasks = @();																							
$TaskIdsToRun = New-Object Collections.Generic.List[int]
$RecipientEmailForExecutionLog = New-Object Collections.Generic.List[String];
$executionLogFilePaths = New-Object Collections.Generic.List[String];
$queryNamesAndLinkedRecipients = @()
$queryNamesWithExecutionStatus = @()
$queryNamesWithFailedExecutionStatus = @()
$executionStatus = $false



#Helper Function----------------------

#---------------------------------------------
#Description:To Create Items[directory/file] if not found
#Params:
#	$fullPath[String] ~ p -> Full path of the item that is to create
#	$type[String] ~ t -> Item type [Directory|File]
#---------------------------------------------
function Create-IfNotFound {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("p")]
		[String] $fullPath,
		[Parameter(Mandatory=$True)]
		[Alias("t")]
		[String] $type
	)
    if(!(Test-Path $fullPath)) {
		New-Item -Path $fullPath -ItemType $type
	}
}

#---------------------------------------------
#Description:Initial Setup-up for folders if not found
#---------------------------------------------
function Init-Setup {
	Create-IfNotFound -p $script:BackupPath -t "Directory"
	Create-IfNotFound -p $script:RunSQLTaskSchedulerScripts -t "Directory"
	Create-IfNotFound -p $script:BatchLogFilePath -t "File"
	Create-IfNotFound -p $script:ErrorLogFilePath -t "File"
	Create-IfNotFound -p $script:MessageLogFilePath -t "File"
    Create-IfNotFound -p $script:outputFolderPath -t "Directory"
    Clear-Content $script:ErrorLogFilePath
    Clean-CreatedResource
}



#---------------------------------------------
#Description:To get all the sql tasks from SQL-Config-FIle
#---------------------------------------------
function Get-SQLTasks {
	Write-Log  -m "Getting SQL Tasks from SQLConfif file $ConfigFilePath"
	$script:SQLTasks = Import-Csv $ConfigFilePath | Sort-Object * -Unique
	return $script:SQLTasks
}

#---------------------------------------------
#Description:Filter the sql task that needed to be run
##Params:
#	$sqlTask[PSCustomObject] ~ st -> SqlTask defined in SQLTaskConfig.csv
#---------------------------------------------
function Fetch-TaskToRun {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("st")]
		[PSCustomObject] $sqlTask
	)
	$SQLFullName = [string]::concat($SQLTaskSchedulerScripts, $sqlTask.ScriptName)
    $currentTime = [Datetime]::Now
	$cronExpression = [string]$sqlTask.CronExpression
	$startTimeDate = ([DateTime]$sqlTask.StartTimeDate).AddHours(-([DateTime]$sqlTask.StartTimeDate).Hour).AddMinutes(-([DateTime]$sqlTask.StartTimeDate).Minute)
    $endTimeDate = [Datetime]::MaxValue

    if(![string]::IsNullOrWhiteSpace($sqlTask.EndTimeDate) -and ![string]::IsNullOrEmpty($sqlTask.EndTimeDate)) {
        $endTimeDate = [Datetime]$sqlTask.EndTimeDate
    }
    $lastRunTime = $sqlTask.LastRunTime
	$baseTime = $currentTime

    if($endTimeDate -lt $currentTime) {    #Script is expired so moved to BackupPath
		return $SqlTaskExpired
	}
		

	if(Test-Path $SQLFullName) {

        

		if($startTimeDate -gt $currentTime) { 
			return $SqlTaskNotScheduledToRun
		}

		if($startTimeDate -lt $currentTime -and [string]::IsNullOrWhiteSpace($lastRunTime)) {
			$baseTime = $startTimeDate
		}

		if(![string]::IsNullOrWhiteSpace($lastRunTime) -and $startTimeDate -lt $currentTime -and $startTimeDate -lt $lastRunTime) {
			$baseTime = $lastRunTime
		}

		$scheduledTime = [ncrontab.crontabschedule]([ncrontab.crontabschedule]::parse($cronExpression))
		$nextScheduledTime = $scheduledTime.GetNextOccurrence($baseTime);

		if($nextScheduledTime -lt $currentTime) {
			$script:ScriptsFound.Add($SQLFullName)
			return $SqlTaskReadyToRun
		} else {
			return $SqlTaskNotScheduledToRun
		}

	}else {
        $script:ScriptsNotFound.Add($SQLFullName)
        Write-Log -path $ErrorLogFilePath -m "$SQLFileFullName file doesn't exist";
		Write-Output $sqlTask.ScriptName "is not found"
		Write-Log  -m "$($sqlTask.ScriptName) is not found";
	}
	return $SqlTaskNotScheduledToRun
}

#---------------------------------------------
#Description:Get all the email distribution list
#---------------------------------------------
function Get-EmailDLs {
	if(Test-Path $EmailDistListPath) {
		$lines = Get-Content $EmailDistListPath
		foreach($line in $lines) {
			$script:Recipients.Add($line.Trim());
		}
		Write-Log  -m "Getting Email DL from $EmailDistListPath";
		return $true;
	} else {
		return $false;
	}
}

#---------------------------------------------
#Description: Send Email Functionality
#Params:
#	$subject[string] ~ t -> Email Type[SUCCESS,FAILURE]
#	$body[string] ~ b -> Email body
#---------------------------------------------
function Send-Email {
	[CmdletBinding()]
	param(
		[Alias("et")]
		[string] $emailType
	)

	if($emailType -eq "SUCCESS" -and $script:ScriptsNotFound.Count -eq 0 -and $script:ScriptsFound.Count -ne 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) has completed - Successfully"
		$body = "
			<p>Following list of scripts are <b>executed</b> by SQLTaskScheduler at $(Time-Stamp) ET<p>
			<ol>
				$($script:ScriptsFound | ForEach-Object {"<li>$_</li>"})
			</ol>
		"
	}

	if($emailType -eq "SUCCESS" -and $script:ScriptsNotFound.Count -eq 0 -and $script:ScriptsFound.Count -eq 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) has completed - Successfully"
		$body = "
			<p>No scripts to run at $(Time-Stamp) ET<p>
		"
	}
	
	if($emailType -eq "FAILURE" -and $script:ScriptsNotFound.Count -gt 0 -and $script:ScriptsFound.Count -eq 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) has exception - Failed"
		$body = "
			<p>Following list of scripts <b>not executed</b> at $(Time-Stamp) ET.<p>
			<ol>
				$($script:ScriptsNotFound | ForEach-Object {"<li>$_</li>"})
			<ol>
			<p>Please refer $script:MessageLogFilePath</p>
		"
	}

	if($emailType -eq "FAILURE" -and $script:ScriptsFound.Count -gt 0 -and $script:ScriptsNotFound.Count -gt 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) has exception - Failed"
		$body = "
			<p>Following list of scripts are <b>executed</b> by SQLTaskScheduler at $(Time-Stamp) ET<p>
			<ol>
				$($script:ScriptsFound | ForEach-Object {"<li>$_</li>"})
			</ol>
			<p>Following list of scripts not executed at $(Time-Stamp) ET.<p>
			<ol>
				$($script:ScriptsNotFound | ForEach-Object {"<li>$_</li>"})
			<ol>
			<p>Please refer $script:MessageLogFilePath</p>
		"
	}

    if($emailType -eq "FAILURE" -and $script:ScriptsFound.Count -gt 0 -and $script:ScriptsNotFound.Count -gt 0 -and $script:executionStatus -and $queryNamesWithFailedExecutionStatus.Count -gt 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) has exception - Failed"
		$body = "
			<p>Following list of scripts are <b>executed</b> at $(Time-Stamp) ET<p>
			<ol>
				$($script:ScriptsFound | ForEach-Object {"<li>$_</li>"})
			</ol>
			<p>Following list of scripts <b>not executed</b> at $(Time-Stamp) ET.<p>
			<ol>
				$($script:ScriptsNotFound | ForEach-Object {"<li>$_</li>"})
			</ol>
            <p>Execution Status for the below sql script/s <b>Failed</b>:</p>
            <ol>
				$($script:queryNamesWithFailedExecutionStatus | ForEach-Object {"<li>$_</li>"})
			</ol>
			<p>Please refer $script:MessageLogFilePath</p>
		"
	}


	if($emailType -eq "FAILURE" -and $script:ScriptsFound.Count -eq 0 -and $script:ScriptsNotFound.Count -eq 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) - Failed"
		$body = "
			<p>Execution of SQLTaskScheduler is <b>failed</b> at $(Time-Stamp) ET</p>
			<p>Please refer below path</p>
			<a>$ErrorLogFilePath</a>
		"
	}

    if($emailType -eq "FAILURE" -and $script:ScriptsNotFound.Count -eq 0 -and $script:ScriptsFound.Count -gt 0 -and $script:executionStatus -and $queryNamesWithFailedExecutionStatus.Count -gt 0) {
		$subject = "$($script:Environment): Job $($script:JobRun) has completed - Failed"
		$body = "
			<p>Following list of scripts are <b>executed</b> by SQLTaskScheduler at $(Time-Stamp) ET<p>
			<ol>
				$($script:ScriptsFound | ForEach-Object {"<li>$_</li>"})
			</ol>
            <p>Execution Status for the below sql script/s <b>Failed</b>:</p>
            <ol>
				$($script:queryNamesWithFailedExecutionStatus | ForEach-Object {"<li>$_</li>"})
			</ol>
            <p>Please refer below path</p>
			<a>$($MessageLogFilePath)</a>
		"
	}

	if(Get-EmailDLs) {
		send-mailmessage -To $script:Recipients -From $script:SendFromAddress -Subject $subject -Body $body `
		-BodyAsHtml `
		-SmtpServer $script:SMTPRelay
		Write-Log  -m "Email sent";
	} else {
		Write-Log  -m "Email DL from $EmailDistListPath not found";
		Write-Log -path $ErrorLogFilePath -m "Email DL from $EmailDistListPath not found";
		write-Host "$(Time-Stamp): Could not find email distribution list: " $DLFile
		write-Host "$(Time-Stamp): Exiting RunSQLScheduledTasks.ps1 script...."
		Exit 1001
	}
}

#---------------------------------------------
#Description:Write status to batch log
#Params:
#	$LogFilePath[string] ~ path -> Path of the log file
#	$isSuccess[boolean] ~ m -> Bool flag which indicated successfull run or failure
#---------------------------------------------
function Write-StatusTologFile {
	[CmdletBinding()]
	param(
		[Alias("path")]
		[string] $LogFilePath,
		[Alias("status")]
		[bool] $isSuccess
	)
	if(Test-Path $LogFilePath) {
		if($isSuccess) {
			Write-Output "SUCCESS" | Out-File $LogFilePath -encoding ascii -Force
		}else {
			Write-Output "FAILURE" | Out-File $LogFilePath -encoding ascii -Force
		}
		return $True
	} else {
		return $False
	}
}

#---------------------------------------------
#Description:Write message or error log
#Params:
#	$LogFilePath[string] ~ path -> Path of the log file
#	$message[string] ~ m -> Message to be put in the log file
#---------------------------------------------
function Write-Log {
	[CmdletBinding()]
	param(
		[Alias("path")]
		[string] $LogFilePath,
		[Alias("m")]
		[string] $message
	)
	if(![string]::IsNullOrEmpty($LogFilePath) -and (Test-Path $LogFilePath)) {
		Add-Content $LogFilePath "$(Time-Stamp):$message" -Force
		Add-Content $MessageLogFilePath "$(Time-Stamp):$message" -Force
	} else {
		Add-Content $MessageLogFilePath "$(Time-Stamp):$message" -Force
	}
}

#---------------------------------------------
#Description:Get current timestamp
#---------------------------------------------
function Time-Stamp {
	return [Datetime]::now.ToString($script:DateTimeFormat)
}

#---------------------------------------------
#Description:Copy SQL File from scheduled SQLTaskSchedulerScripts to RunSQLTaskSchedulerScripts
#Params:
#	$SQLFullName[string] ~ name -> Sql File full path which needs to be copied to RunSQLTaskSchedulerScripts
#---------------------------------------------
function Copy-SQLFile {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("name")]
		[string] $SQLFullName
	)
	Copy-Item -path $SQLFullName -Destination $script:RunSQLTaskSchedulerScripts
	Write-Host "$(Time-Stamp): File Copied to $script:RunSQLTaskSchedulerScripts folder"
	Write-Log -m "File Copied to $script:RunSQLTaskSchedulerScripts folder";
}

#---------------------------------------------
#Description:Move SQL File from SQLTaskSchedulerScripts path to BackupPath
#Params:
#	$SQLFullName[string] ~ name -> Sql File full path which needs to be moved to BackupPath
#---------------------------------------------
function Move-SQLFile {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("name")]
		[string] $SQLFullName
	)
	Move-Item -path $SQLFullName -Destination "$script:CurrentBackupPath"
	Write-Host "$(Time-Stamp): File Moved to $script:CurrentBackupPath folder"
	Write-Log  -m "File Moved to $script:CurrentBackupPath folder";
}

#---------------------------------------------
#Description:Update SQLConfig file 
#---------------------------------------------
function Update-SQLConfigFile {
	$script:SQLTasks | Export-Csv $ConfigFilePath -NoTypeInformation
	Write-Host "$(Time-Stamp): SQLTaskConfig updated"
	Write-Log  -m "SQLTaskConfig updated";
}

#---------------------------------------------
#Description:Update SQL Tasks runtime 
#Params:
#	$TaskId[string] ~ id -> Id of the task that is to be updated
#	$RunTime[string] ~ t -> Value for lastRunTime that is to be updated
#---------------------------------------------
function Update-SQLTaskRunTime {
	[CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("id")]
		[string] $TaskId,
		[Parameter(Mandatory=$True)]
		[Alias("t")]
		[string] $RunTime
	)
	$task = $script:SQLTasks | Where-Object { $_.TaskId -eq $TaskId }
	$task.LastRunTime = $RunTime
}


#---------------------------------------------
#Description: Get all the email DL's defined in the RecipientEmail field 
#Params:
#	$recipientEmails[string] ~ re -> Email's seperated by ","
#---------------------------------------------
function Get-QueryNameWithLinkedRecipients {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
        [AllowEmptyString()]
		[Alias("re")]
		[String] $recipientEmails,
        [Parameter(Mandatory=$True)]
		[Alias("query")]
		[String] $queryName
	)
    $recipients = $recipientEmails.Split(",").Trim();
    if(![string]::IsNullOrEmpty($recipientEmails) -and ![string]::IsNullOrWhiteSpace($recipientEmails)) {
        if($script:queryNamesAndLinkedRecipients.Count -gt 0) {
            foreach($data in $script:queryNamesAndLinkedRecipients){
                if((Compare-Object $data.recipients $recipients) -eq $null) {
                    $data.script += $queryName
                    return $true;
                }
            }
        }
        $script:queryNamesAndLinkedRecipients += (@{script = ,$queryName; recipients = $recipients;})
        return $true;
    }
    return $false;
}

#---------------------------------------------
#Description: Get current execution log's of the executed scripts 
#Params:
#      $queryName[string] ~ script -> SQL Query Name
#---------------------------------------------
function Get-ExecutionLogPath {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("script")]
		[String] $queryName
	)
	$executionLogsPath = @();
    $ExecutionStatusFolderName = gci $BackupSQLScriptsPath | ? { $_.PSIsContainer } | sort LastWriteTime -desc | select -f 1
    if(Test-Path "$($ExecutionStatusFolderName.FullName)\ExecutionStatus_messages.txt") {
        Write-Log  -m "Getting execution status messages for $($queryName)"
        if(Generate-ExecutionMessages -script $queryName -path "$($ExecutionStatusFolderName.FullName)\ExecutionStatus_messages.txt" -outFilePath "$($outputFolderPath)\ExecutionStatus_messages.txt") {
            $executionLogsPath += "$($outputFolderPath)\ExecutionStatus_messages.txt";
        }
    }
    if(Generate-ExecutionStatus -script $queryName -path "$($ExecutionStatusFolderName.FullName)\ExecutionStatus.txt" -outFilePath "$($outputFolderPath)\ExecutionStatus.txt") {
        Write-Log  -m "Getting execution status for $($queryName)"
        $executionLogsPath += "$($outputFolderPath)\ExecutionStatus.txt";
    }
    return $executionLogsPath;
}


#---------------------------------------------
#Description: Send email functionality for the recipients who need execution log of the executed scripts
#Params:
#	$queryNames[string[]] ~ scripts -> SQL Query Names
#   $linkedRecipients[string[]] ~ lr -> Emails
#---------------------------------------------
function Send-EmailWithExecutionLog {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("scripts")]
		[String[]] $queryNames,
        [Parameter(Mandatory=$True)]
		[Alias("lr")]
		[String[]] $linkedRecipients
	)

	
    $executionLogsPath = @();
    foreach($query in $queryNames){
        $executionLogsPath += Get-ExecutionLogPath -script $query;
    }
    $executionLogsPath = $executionLogsPath | select -Unique;
    Get-EmailDLs
    $subject = "$($script:Environment): $($script:JobRun) - Srcipt Execution Status $(if($script:queryNamesWithExecutionStatus.Count -gt 1) {} else {"- $($script:queryNamesWithExecutionStatus[0].Values)"})"
	$body = "
		<p>Please find attached <b>Execution Status</b> for the following list of scripts which are executed by SQLTaskScheduler at $(Time-Stamp) ET<p>
		<ol>
			$($script:queryNamesWithExecutionStatus | ForEach-Object {"<li>$($_.Keys) - <b>$($_.Values)</b></li>"})
		</ol>
	"
	send-mailmessage -To $linkedRecipients -From $script:SendFromAddress -Cc $script:Recipients -Subject $subject `
	-Body $body -BodyAsHtml -Attachments $executionLogsPath `
	-SmtpServer $script:SMTPRelay
	Write-Log  -m "Email sent to Recipients with Execution Status";
}


#---------------------------------------------
#Description: Generate Execution status for a given query
#Params:
#	$queryName[string] ~ script -> SQL Query Name
#   $filePath[string] ~ path -> File Path to read
#   $outputFilePath[string] ~ outFilePath -> File path to write
#---------------------------------------------
function Generate-ExecutionStatus {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("script")]
		[String] $queryName,
        [Parameter(Mandatory=$True)]
		[Alias("path")]
		[String] $filePath,
        [Parameter(Mandatory=$True)]
		[Alias("outFilePath")]
		[String] $outputFilePath
        
	)
    
    $content = Get-Content $filePath
    $scriptNameInFile = $content | Where-Object {$_ -like "*$($queryName)*"} | Select -First 1
    $counter = 0;
    foreach($line in $content) {
        if($scriptNameInFile -eq $line) {
            $i = $counter
            while($content[$i] -ne "") {
                if($content.Count -eq $i) {
                    return $True;
                }
                if($content[$i] -like "Execution status:*") {
                    if($content[$i].Split(" ")[2].ToLower() -eq "failed") { 
                        $script:executionStatus = $true; 
                        $script:queryNamesWithFailedExecutionStatus += $queryName;
                    }
                    $script:queryNamesWithExecutionStatus += @{$queryName=$content[$i].Split(" ")[2]};
                }
                Add-Content -Path $outputFilePath -Value $content[$i]
                $i++;
            }
            Add-Content -Path $outputFilePath -Value `n
            return $True;
        }
        $counter++;
    }
    return $False;
}


#---------------------------------------------
#Description: Generate Execution messages for a given query
#Params:
#	$queryName[string] ~ script -> SQL Query Name
#   $filePath[string] ~ path -> File Path to read
#   $outputFilePath[string] ~ outFilePath -> File path to write
#---------------------------------------------
function Generate-ExecutionMessages {
    [CmdletBinding()]
	Param(
		[Parameter(Mandatory=$True)]
		[Alias("script")]
		[String] $queryName,
        [Parameter(Mandatory=$True)]
		[Alias("path")]
		[String] $filePath,
        [Parameter(Mandatory=$True)]
		[Alias("outFilePath")]
		[String] $outputFilePath
        
	)

    $content = Get-Content $filePath
    $scriptNameInFile = $content | Where-Object {$_ -like "*$($queryName)*"} | Select -First 1 
    if($scriptNameInFile -eq "") { return $false; }
    $counter = 0;
    foreach($line in $content) {
        if($line -like "*$($queryName)*") {
            $i = $counter
            while($content[$i] -ne "") {
                if($content.Count -eq $i) {
                    return $true;
                }
                Add-Content -Path $outputFilePath -Value $content[$i];
                $i++;
            }
            Add-Content -Path $outputFilePath -Value `n`n
        }
        $counter++;
    }
    return $true;
}


#---------------------------------------------
#Description: Delete files created to send as attachments in mail
#---------------------------------------------
function Clean-CreatedResource {
    if(Test-Path "$($outputFolderPath)\ExecutionStatus.txt") {
        Remove-Item -Path "$($outputFolderPath)\ExecutionStatus.txt"
    }
    if(Test-Path "$($outputFolderPath)\ExecutionStatus_messages.txt") {
        Remove-Item -Path "$($outputFolderPath)\ExecutionStatus_messages.txt"
    }
}


#----------------------------------------
# Execution of the Main script
#----------------------------------------

Init-Setup

foreach ($sqlTask in Get-SQLTasks) {
	if($sqlTask -ne $True) {
		$result = Fetch-TaskToRun -st $sqlTask
        $SQLFileFullName = [string]::Concat($SQLTaskSchedulerScripts,$sqlTask.ScriptName)
		if((Test-Path $SQLFileFullName) -and $result -eq $SqlTaskReadyToRun) {
			Copy-SQLFile -name $SQLFileFullName
			$TaskIdsToRun.Add($sqlTask.TaskId)
			Get-QueryNameWithLinkedRecipients -re $sqlTask.RecipientEmail -query $sqlTask.ScriptName
		}elseif($result -eq $SqlTaskExpired -and (Test-Path $SQLFileFullName)) {
			Create-IfNotFound -p $script:CurrentBackupPath -t "Directory"
            Move-SQLFile -name $SQLFileFullName
		}
    }
}



try {
	if($script:TaskIdsToRun.Count -gt 0) {
		$process = Start-process -FilePath $script:SQLRunToolPath -WindowStyle Maximized -ArgumentList "SubFolderPathForProcess=\\$script:RunSQLTaskSchedulerScriptsFolderName\\" -PassThru -Wait 
		Write-Log  -m "Running SQLRunTool..."
		$processRunTime = [DateTime]::Now.ToString($script:DateTimeFormat)
		$TaskIdsToRun | ForEach-Object -Process { Update-SQLTaskRunTime -id $_ -t $processRunTime }
		Update-SQLConfigFile
		if($script:queryNamesAndLinkedRecipients.Count  -gt 0) {
            foreach ($data in $script:queryNamesAndLinkedRecipients) {
                Send-EmailWithExecutionLog -scripts $data.script -lr $data.recipients
                Clean-CreatedResource
                $script:queryNamesWithExecutionStatus = @();
            }
		}
        if($script:executionStatus) {
            $script:queryNamesWithFailedExecutionStatus | ForEach-Object { Write-Log  -m "Execution Status for $($_) is failed" };
	        Write-StatusTologFile -status $False -path $BatchLogFilePath
            Send-Email -et "FAILURE"
            exit 1
        }
	} elseif($script:ScriptsNotFound.Count -gt 0) {
		Write-Log  -m "Some Scheduled Scripts are not executed in this runtime";
	    Write-StatusTologFile -status $False -path $BatchLogFilePath
        Send-Email -et "FAILURE"
        exit 1

	} else {
        Write-Log  -m "No Scripts are scheduled in this runtime";
    }
    Send-Email -et "SUCCESS"
	Write-StatusTologFile -status $True -path $BatchLogFilePath
	Write-Log  -m "Successfully completed"
	
} catch {
	Write-Log  -m "Error occured please check error log";
	Write-Log -path $ErrorLogFilePath -m "$Error";
	Write-StatusTologFile -status $False -path $BatchLogFilePath 
	Send-Email -et "FAILURE"
    exit 1
}

exit 0