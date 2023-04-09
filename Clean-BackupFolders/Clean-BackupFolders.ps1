<#
    .SYNOPSIS
        Delete Backup folders of DWH Data.
    .DESCRIPTION
        Powershell script that deletes DWH folders older than a threshold days defined in config file.

    .PARAMETER FolderType
       folder type to delete specific backup folders
    .INPUTS
       None. You can not pipe data 
    .OUTPUTS 
       None. Don't return any one value. It writes output in message log.
    .NOTES
        Program: Clean-BackupFolders.ps1
        Author: Rajesh Kolla
        Date: 04/08/2023
#>
function Clear-BackupFolders {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("DWHExtract","DWHMart")]
        [string]$FolderType
        )
    
    begin {
        $configFile=Join-Path $PSScriptRoot "Clean-BackupFolders.json"
        $Ddrive="D:\"
        $Logs= Join-Path $Ddrive "Logs"
        $DWHData= Join-Path $Ddrive "DWHData"
        $DWHExtract=Join-Path $DWHData  "DWHExtract"
        $DWHExtractBackup=Join-Path $DWHExtract  "Backup"
        $DWHmartBackup=Join-Path $DWHExtract  "DWHMart\Backup"
        $date= Get-Date -Format"yyyyMMddmmss"
        $batchLog=Join-Path $Logs "BatchLog\Clean-BackupFolders.txt"
        $msgLog=Join-Path $Logs "MsgLog\Clean-BackupFolders-$date-log.txt"
        $errorLog=Join-Path $Logs "ErrorLog\Clean-BackupFolders.txt"
        $pathsToDelete=Get-Content -Path $configFile |ConvertFrom-Json |Convert-ToHashTable
        "Failure" |Out-File $batchLog
    }
    process {
        $pathToDelete =$pathsToDelete[$FolderType].FullPathToDelete
        $thresholdDate =([System.DateTime](Get-Date)).AddDays(-1*$pathsToDelete[$FolderType].RetentionPeriod)
            if((Test-Path $pathToDelete) -and ($pathToDelete -eq $DWHExtractBackup -or $pathToDelete -eq $DWHmartBackup)){
            Get-ChildItem $pathToDelete  |Where-Object {$_.LastWriteTime -le $thresholdDate} |&{Process {Clear-Folder $_  }};
            }
         }
    end {
        if(!(Test-Path $msgLog) -and !(Test-Path $errorLog)){

            $msg="No files\folder to clean for rention period."
            $msg |Out-File $msgLog
         }
        "Success" |Out-File $batchLog
    }
}
function Convert-ToHashTable {
      [CmdletBinding()]
        param(
            [parameter(Mandatory=$true, ValueFromPipeline=$true)]
            [psobject]$inputObject
        )

    begin {
        $hash=@{}
    }
    process {
        $inputObject.psobject.properties |&{Process{$hash[$_.Name]=[RetentionConfig]::new($_.Value.Path ,$_.Value.RetentionPeriod)}};
    }
    end {
        return $hash
    }
}
function Clear-Folder {
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [Alias("DI")]
    [System.IO.DirectoryInfo]$directoryInfoToDelete
    )
  process {
    try {
         $FullPathToClean=$directoryInfoToDelete.FullName
         if(Test-Path $FullPathToClean){
            $emptyFolder=$FullPathToClean +"EmptyFolder"
            New-Item -ItemType Directory $emptyFolder
            Robocopy.exe $FullPathToClean  /MIR /MT:24 /w:5  /purge /v /LOG+:$msgLog /NFL /NDL
            Remove-Item $FullPathToClean
            $msg = "`n $FullPathToClean folder has been deleted."
            $msg |Out-File $msgLog -Append
            Write-Host $msg
        }
    }
    catch {
        $msg="Exception in execution of Clear-Folder for $FullPathToClean `n" +$_
        $msg |Out-File $errorLog
        Write-Error -Message $msg -ErrorAction Stop
    }
    
  }
}

class RetentionConfig {
    [string]$FullPathToDelete
    [int]$RetentionPeriod
    RetentionConfig(){
        $this.FullPathToDelete = ""
        $this.RetentionPeriod=30
    }

    RetentionConfig(
        [string]$path,
        [int]$rPeriod
    ){
        $this.FullPathToDelete = $path
        $this.RetentionPeriod = $rPeriod
    }
}

