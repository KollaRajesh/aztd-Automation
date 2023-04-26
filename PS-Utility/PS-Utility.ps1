<#
   .Notes
     Script: PS-Utility.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>

function Convert-ToHashTable {
 <#
    .SYNOPSIS
        Helper function to take a JSON string and turn it into a hashtable
    .DESCRIPTION
        The built in ConvertFrom-Json file produces as PSCustomObject that has case-insensitive keys. This means that
        if the JSON string has different keys but of the same name, e.g. 'size' and 'Size' the comversion will fail.
        Additionally to turn a PSCustomObject into a hashtable requires another function to perform the operation.

    .INPUTS
    [System.Management.Automation.PSCustomObject] , You can pipe objects to Convert-ToHashTable

    .OUTPUTS
    Hashtable

    .ExAMPLE
     PS > Get-Content -Path ".\Environments.json" -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |ConvertFrom-Json |Convert-ToHashTable

      Name                           Value                                                                                                                                                                                                     
      ----                           -----                                                                                                                                                                                                     
    PROD_NonDR                     {ProdWeb-01, ProdWeb-02, ProdWeb-03, ProdWeb-04...}                                                                                                                                                       
    Test3                          {Test3-Web-01, Test3-Web-02, Test3-Web-03, Test3-Web-04...}                                                                                                                                               
    Test2                          {Test2-Web-01, Test2-Web-02}                                                                                                                                                                              
    Test1                          {Test1-Web-01, Test1-Web-02}                                                                                                                                                                              
    Test6                          {Test6-Web-01, Test6-Web-02}                                                                                                                                                                              
    PROD_DR                        {ProdWeb-07, ProdWeb-08, ProdWeb-09, ProdWeb-10...}                                                                                                                                                       
    Test5                          {Test5-Web-01, Test5-Web-02}   

    .LINK 
        ConvertFrom-Json
    .LINK 
        Get-Content

#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true,ValueFromPipeline=$true)]
    [psobject] $inputObject
  )
  
  begin {
    $hash =@{}
  }
  
  process {
    $inputObject.psobject.properties|&{process{$hash[$_.Name]=[string[]]$_.Value}};
    
  }
  end {
   return $hash    
  }
}

function Get-Servers {
<#
  .SYNOPSIS
  # Get environment servers for given envrionment

  .DESCRIPTION
    Read list of servers for all environments from config and return lis of servers based on given environment

  .PARAMETER Environment
      Environment Name 

 .PARAMETER ScriptPath
       Script Path , if ScriptPath provides, read server details from Environments.json from script path else it will read from Environments.json under PS-Utility folder
  .EXAMPLE 
      Get-Servers -Environment Test1

      Key   Value                             
      ---   -----                             
      Test2 {Test2-Web-BE-01, Test2-Web-BE-02}
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$true)]
    [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
    [String]$Environment,
    [Parameter(Mandatory=$false)]
    [ValidateNotNullOrEmpty]
    [string]$ScriptPath
    )
    begin {
       if ([string]::IsNullOrWhiteSpace($ScriptPath)){
          $ScriptPath =Get-UtilityScriptPath
       }
        $WebBackendServers=New-Object 'System.Collections.Generic.Dictionary[String,System.Collections.Generic.List[string]]';
        $EnvironmentsConfigFile=Join-Path $PSScriptRoot "Environments.json"
        $WebBeServersForAllEnv= Get-Content -Path $EnvironmentsConfigFile -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |ConvertFrom-Json |Convert-ToHashTable
      }
    process {
        $WebBackendServers.Clear();
        if($WebBeServersForAllEnv.ContainsKey($Environment)){
            $WebBackendServers.Add($Environment,[string[]]$WebBeServersForAllEnv[$Environment])
        }elseif($Environment.ToUpper() -eq "PROD"){
              $WebBeServersForAllEnv.Keys |Where-Object {$_ -like "$Environment"} | &{Process{$WebBackendServers.Add($_ , [string[]]$WebBeServersForAllEnv[$_]) }};
        }
        elseif($Environment.ToUpper() -eq "QA"){
              $WebBeServersForAllEnv.Keys |Where-Object {$_ -like "Test"} | &{Process{$WebBackendServers.Add($_ , [string[]]$WebBeServersForAllEnv[$_])}};
        }
    }
    end {
        return $WebBackendServers
    }
  }

function Get-ConfigValues {
<#
  .SYNOPSIS
  Get Config values from AppConfig.json

  .DESCRIPTION
  Read list of config values from AppConfig.json if ScriptPath Provides, Environments.json will read from script path 
  else it will read from Environment.json under PS-Utility.

  .PARAMETER ScriptPath
   Script Path which is send from calling application.

  .EXAMPLE
   Get-ConfigValues 

   .EXAMPLE
   Get-ConfigValues -ScriptPath "D:\AppPool-Management\"
#>
  [CmdletBinding()]
  param (
    # Parameter help description
    [Parameter(Mandatory=$false)]
    [string]$ScriptPath
  )
    begin {
      if (([string]::IsNullOrWhiteSpace($ScriptPath)) -or !(Test-path $ScriptPath) ){
          $ScriptPath =Get-UtilityScriptPath
      }
      $AppConfigFile=Join-Path $ScriptPath "AppConfig.json" 
    }
    process {
      $result= Get-Content -Path $AppConfigFile  -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue 
    }
    end {
      return $result
    }
}

function Convert-ToList {
<#
.SYNOPSIS
  Convert string into list by using spliter.

.PARAMETER Value
 Value of string to convert into list.

.PARAMETER Spliter
 Value of the spliter to convert into list.

#>
[CmdletBinding()]
param (
    [Parameter(Mandatory=$false,HelpMessage="String values to convert into list")]
    [string]$Value,
    [Parameter(Mandatory=$false,HelpMessage="Spliter value to convert into list")]
    [string]$Spliter
  )
    $list =New-Object Collection.Generic.List[String]
    ($Value -split $Spliter) |ForEach-Object {if (-not [string]::IsNullOrWhiteSpace($_)){$list.Add($_)} }
}

function Convert-ToString {
  <#
  .SYNOPSIS
   Convert list of string values into string by using delimiter.
  
  .PARAMETER list
   List of string values.
  
  .PARAMETER Delimiter
   Delimiter value.
  
#>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$false,HelpMessage="List of string values.")]
      [Collections.Generic.List[string]] $List,
      [Parameter(Mandatory=$false,HelpMessage="Delimiter value.")]
      [string] $Delimiter
  )
    if([string]::IsNullOrWhiteSpace($Delimiter)){$Delimiter="`n"}
      $result = [string]::Empty

      if(($null -ne $List ) -and ($List.Count -gt 0)){
        for ($i = 0; $i -lt $List.Count-1; $i++) {$result =$result+$List[$i]+$Delimiter}
        $result=$result+$List[$List.Count-1]
      }
      return $result
}

function New-ItemIfNotExists {
  <#
  .SYNOPSIS
  This helper commandlet helps to create folder\file if not exists
    
  .PARAMETER Path
    Path of the folder\file
  
  .PARAMETER ItemType
   ItemType indicates whether it is Directory or file
  
  .EXAMPLE
  An example
  
  .NOTES
  General notes
  #>
  [CmdletBinding()]
  param (
    # Parameter help description
    [Parameter(Mandatory=$true,HelpMessage="Path of the file (or) directory")]
    [string]$Path,
    [Parameter(Mandatory=$true,HelpMessage="Item Type")]
    [ValidateSet("Directory","File")]
    [string]$ItemType
  )
    if(!(Test-Path $Path)){
      New-Item -Path $Path -ItemType $ItemType -ErrorAction SilentlyContinue -WarningAction SilentlyContinue
    }
}

function Get-Parent {
  <#
  .SYNOPSIS
  This helper commandlet helps to get parent folder path
  
  .PARAMETER Path
   Path\Location
  
  .EXAMPLE
   Get-Parent -Path "D:\Logs\BatchLog"
  
   Result
   ------
   BatchLog
  #>
  [CmdletBinding()]
  param (
    # Parameter help description
    [Parameter(Mandatory=$true)]
    [string]$Path
  )
  $result =$Path 
  if (Test-Path $Path){$result =Split-Path $Path -Parent }
  return $result
}


function Get-UtilityScriptPath {
  <#
  .SYNOPSIS
   Get Script Path
  
  .EXAMPLE
   $scriptPath=Get-UtilityScriptPath
  #>
  $ScriptPath =$PSScriptRoot 
  if([string]::IsNullOrWhiteSpace($PSScriptRoot) -or !(Test-Path $PSScriptRoot)){
     $ScriptPath=Split-Path -Parent $MyInvocation.MyCommand.Definition
  }
  return $ScriptPath
}

function Test-ChangeTransactionID {
  <#
  .SYNOPSIS
   Test ChangeTransactionID whether it is valid change ticket\Incident format
  
  .PARAMETER ChangeTransactionID
  ChangeTransactionID whether it is Incident or change
  
  .EXAMPLE
   Test-ChangeTransactionID CHG11667849

  .EXAMPLE
   Test-ChangeTransactionID INC18711123
 
  #>
  [CmdletBinding()]
  param (
    [Parameter(Mandatory=$true)]
    [string]$ChangeTransactionID
  )
  if($null -eq $ChangeTransactionID ) {return $false}
  $ChangeTransactionID =$ChangeTransactionID.ToUpper()
  return ($ChangeTransactionID -match "^[CHG]{3}[0-9]{8}$" -or $ChangeTransactionID -match "^[INC]{3}[0-9]{8}$")
}