<# 

    .NOTES
        Script:PS-Utility.ps1
        Version :1.0 - initial version
        Author: Rajesh Kolla
        Last Edit: 2023-04-23
        
 #>
 function Convert-ToOrderedDictionary{
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
       .EXAMPLE
           PS > Get-Content -Path ".\Environments.json" -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |ConvertFrom-Json | ConvertTO-OrderedDictionary 
           
            Name                           Value                                                                                                                                                                                                                             
            ----                           -----                                                                                                                                                                                                                             
            PROD_NA                        {VCWP003147, VCWP003148, VCWP003149, VCWP003155...}                                                                                                                                                                               
            PROD_RW                        {VCWP003152, VCWP003153, VCWP003154, VCWP003159...}                                                                                                                                                                               
            SLO1                           {VCWQ003182, VCWQ003205}                                                                                                                                                                                                          
            SLO2                           {VCWQ003180}                                                                                                                                                                                                                      
            SLO3                           {VCWQ003172, VCWQ003173, VCWQ003174, VCWQ003175...}                                                                                                                                                                               
            SLO5                           {VCWQ003168, VCWQ003169}                                                                                                                                                                                                          
            SLO6                           {VCWQ003165, VCWQ003164}  

       .EXAMPLE
           PS > Get-Content -Path $AppConfigFile -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue |ConvertFrom-Json | ConvertTO-OrderedDictionary 

             Name                           Value                                                                                                                                                                                                                             
             ----                           -----                                                                                                                                                                                                                             
        BatchMonitorPath               D:\BatchMonitor                                                                                                                                                                                                                   
        EMailConfig                    {SMTPRelay, SendFromAddress, CCRecipients, Recipients}                                                                                                                                                                            

       .EXAMPLE
           PS > $(@("Test", "Test2","blue")) |ConvertTO-OrderedDictionary

            Name                           Value                                                                                                                                                                                                                             
            ----                           -----                                                                                                                                                                                                                             
            0                              Test                                                                                                                                                                                                                              
            1                              Test2                                                                                                                                                                                                                             
            2                              blue                                                                                                                                                                                                                              


           ConvertFrom-Json
       .LINK 
           Get-Content
   #>

       [CmdletBinding()]
        [OutputType('System.Collections.Specialized.OrderedDictionary')]
               Param(
               [Parameter(Mandatory=$true,ValueFromPipeline=$true )]
                $inputObject)
      begin {
        $functionName=$($MyInvocation.Mycommand)
        Write-Verbose -Message "$functionName is started."
        $orderedDictionary = [ordered] @{}
    } #close begin block

    process {
            Write-Verbose -Message "Processing - $functionName  with  [$($inputobject.GetType().Name)]."
        if ($inputObject -is [System.Collections.Hashtable])
        {
            Write-Verbose -Message '$inputObject is a HashTable'
            #$orderedDictionary = [ordered]@{}
            $keys = $inputObject.keys | sort-object
            foreach ($key in $keys){
                $orderedDictionary.add($key, $inputObject[$key])
            }
            
        }
        elseif ($inputObject -is [System.Array])
        {
            write-verbose -Message '$inputObject is an Array'
            #$orderedDictionary = [ordered] @{}
            for ($i = 0; $i -lt $inputObject.count; $i++)
            {
                $orderedDictionary.add($i, $inputObject[$i])
            }
         
        }
        elseif ($inputObject -is [System.Collections.Specialized.OrderedDictionary])
        {
            write-verbose -Message '$inputObject is an OrderedDictionary'
            #$orderedDictionary = [ordered] @{}
            $keys = $inputObject.keys
            foreach ($key in $keys)
            {
                $orderedDictionary.add($key, $inputObject[$key])
            }
        }
         elseif ($inputObject -is [System.Management.Automation.PSCustomObject]){
            Write-Verbose -Message "$functionName - Processing [pscustomobject]"

            #$orderedDictionary = [ordered] @{}
             foreach ($prop in $inputObject.psobject.Properties){
                $name = $prop.Name
                $value = $prop.Value
                Write-Verbose -Message "$functionName - Property [$name]"
            

                if ($value -is [System.Management.Automation.PSCustomObject])
                {
                    Write-Verbose -Message "$functionName - Value is PScustomobject"
                    $value = $value | Convert-ToHashTable
                }

                if ($value -is [array])
                {
                    Write-Verbose -Message "$functionName - Value is array"
                    $hashValue = @()
                    if ($value[0] -is [hashtable] -or $value[0] -is [System.Collections.Specialized.OrderedDictionary] -or $value[0] -is [PSCustomObject])
                    {
                       $value | &{Process{ $hashValue += ($item | Convert-ToHashTable)}}
                    }
                    else 
                    {
                        $hashValue = $value
                    }                               
                    $value = $hashValue
                }
                $orderedDictionary.Add($name,$value)
            }
        
      } else
        {
             $orderedDictionary.add($i++,$InputObject)
        }
    }

    end {
         $orderedDictionary
          Write-Verbose -Message "$functionName - Ended"
        }

   }


function Convert-ToHashtable
{
 <#
    .SYNOPSIS
        Converts a PScustomobject to a hashtable
 
    .DESCRIPTION
        Converts a PScustomobject to a hashtable
 
    .PARAMETER InputObject
        The PSCustomObject you want to convert to a hashtable
 
    .EXAMPLE
        $obj = [PSCustomobject]@{
        Name = "Tore"
        Value = "Test"
        }
 
        $obj | Convert-ToHashTable
 
    This will create a hashtable with keys matching the properties of the object.
 
    .INPUTS
        PSCustomObject
 
    .OUTPUTS
        System.Collections.Specialized.OrderedDictionary
 
#>
[cmdletbinding()]
Param (
    [Parameter(ValueFromPipeline)]
    [PSCustomObject]$InputObject
)

Begin
{
    $functionName = $MyInvocation.InvocationName
    Write-Verbose -Message "$functionName - started"
     $orderedDictionary = [ordered]@{}
     $i=0
}

    Process
    {   
        Write-Verbose -Message "$functionName - Processing [$($inputobject.GetType().Name)]" 
        if ($InputObject -is [array])
        {
            Write-Verbose -Message "is array object"
             
             for ($i = 0; $i -lt $inputObject.count; $i++)  {$orderedDictionary.add($i, $inputObject[$i]) }
              #return $orderedDictionary
                  
        } elseif ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.Specialized.OrderedDictionary])
        {
            $inputObject.keys |&{Process{ $orderedDictionary.add($_, $inputObject[$_])}};
            
        }elseif ($InputObject -is [System.Management.Automation.PSCustomObject])
        {
            Write-Verbose -Message "$functionName - Processing [pscustomobject]"

            foreach ($prop in $InputObject.psobject.Properties)
            {
                $name = $prop.Name
                $value = $prop.Value
                Write-Verbose -Message "$functionName - Property [$name]"
            

                if ($value -is [System.Management.Automation.PSCustomObject])
                {
                    Write-Verbose -Message "$functionName - Value is PScustomobject"
                    $value = $value | Convert-ToHashTable                    
                }

                if ($value -is [array])
                {
                    Write-Verbose -Message "$functionName - Value is array"
                    $hashValue = @()
                    if ($value[0] -is [hashtable] -or $value[0] -is [System.Collections.Specialized.OrderedDictionary] -or $value[0] -is [PSCustomObject])
                    {
                        foreach ($item in $value)
                        {            
                            $hashValue += ($item |Convert-ToHashTable)
                        }
                    }
                    else 
                    {
                        $hashValue = $value
                    }                               
                    $value = $hashValue
                }
                $orderedDictionary.Add($name,$value)
            }
        }else {
                $orderedDictionary.add($i++,$InputObject)
            }

    }
    End 
    {
       $orderedDictionary
        Write-Verbose -Message "$functionName - END"
    }
}    

function Merge-WithConfig{
<#
.SYNOPSIS
Merge App Config with Base Config

.DESCRIPTION
This method will merge configuration with base level configuration , it will add Appleavel configuriaton , if doesn't exists in Base level config 
 and also will override with AppLevel config values if exist same config at base level .

.PARAMETER AppConfig
AppConfig OrderedDictionary 

.PARAMETER WithBaseConfig
 BaseConfig OrderedDictionary 

#>
[cmdletbinding()]
Param (
    [Parameter(ValueFromPipeline)]
    [System.Collections.Specialized.OrderedDictionary]$AppConfig,
        [Parameter(ValueFromPipeline=$false)]
    [System.Collections.Specialized.OrderedDictionary]$WithBaseConfig

)
    Begin
    {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - started"
        
    }
    Process
    {   
        Write-Verbose -Message " Processing $functionName - BaseConfig with WithAppConfig "
        if ($null -eq $WithBaseConfig){ $WithBaseConfig=[ordered]@{}}

        
                        if(($null -ne $AppConfig)) {
                            
                                $AppConfig.Keys| ForEach-Object{
                                    $key=$_
                            
                                    if ($WithBaseConfig.Contains($key)){
                                        
                                        $InputObject= $AppConfig[$key]
                                        $BaseInputObject= $WithBaseConfig[$key]

                                        if ($InputObject -is [hashtable] -or $InputObject -is [System.Collections.Specialized.OrderedDictionary])
                                        {
                                            $inputObject.keys |&{ 
                                                Process{
                                                    if ($BaseInputObject.Contains($_)){ 
                                                        $BaseInputObject[$_]=$inputObject[$_]
                                                    }else{
                                                        $BaseInputObject.Add($_, $inputObject[$_])
                                                    }
                                                }};
                                            
                                        }else {

                                            $WithBaseConfig[$Key]= $InputObject
                                        }
                                        
                                    }else {
                                        $WithBaseConfig.Add($key,$AppConfig[$key])
                                    }
                            }
                        }
    }
    end
    {
        $WithBaseConfig
        Write-Verbose -Message "$functionName - END"
    }
}

function Get-EnvironmentConfig {
<#
.SYNOPSIS
    Get Environment config

.DESCRIPTION
 Read configuration from Environment.json file 

.PARAMETER ScriptPath
    Script Path ,if ScriptPath provides , Environments.json will read from script path else it will read from Environments.json under PS-Utility folder

.OUTPUT
    System.Collections.Specialized.OrderedDictionary

.EXAMPLE
    Get-EnvironmentConfig 

    Name                           Value                                                                                                                                                                                                                             
    ----                           -----                                                                                                                                                                                                                             
    PROD_NA                        {WebBackEndNodes, BatchNode}                                                                                                                                                                                                      
    PROD_RW                        {WebBackEndNodes, BatchNode}                                                                                                                                                                                                      
    SLO1                           {WebBackEndNodes, BatchNode}                                                                                                                                                                                                      
    SLO2                           {WebBackEndNodes, BatchNode}                                                                                                                                                                                                      
    SLO3                           {WebBackEndNodes, BatchNode}                                                                                                                                                                                                      
    SLO5                           {WebBackEndNodes, BatchNode}                                                                                                                                                                                                      
    SLO6                           {WebBackEndNodes, BatchNode}

#>    
    [CmdletBinding()]
    [OutputType('System.Collections.Specialized.OrderedDictionary')]
    param (
        [Parameter(Mandatory=$false)]
        [string]$ScriptPath
    )
    begin {
        
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"   
    }
    process {
        Write-Verbose -Message "Processing $functionName ." 
        $EnvironmentsFile="Environments.json"
        $EnvironmentsConfigFilePath=Join-Path $(Get-UtilityScriptPath) $EnvironmentsFile
        $BaseEnvironmentsConfig= Get-Content -Path $EnvironmentsConfigFilePath -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue `
                                             |ConvertFrom-Json |Convert-ToOrderedDictionary

        if(![string]::IsNullOrWhiteSpace($ScriptPath) -and ( Test-Path $(Join-Path $ScriptPath "Environments.json") )){

            $AppLevelEnvironmentsConfigFile=Join-Path $ScriptPath  $EnvironmentsFile

            $BaseEnvironmentsConfig= Get-Content -Path $AppLevelEnvironmentsConfigFile -Raw `
                                            -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue `
                                            |ConvertFrom-Json |Convert-ToOrderedDictionary   `
                                            |Merge-WithConfig -WithBaseConfig $BaseEnvironmentsConfig
            }
    }
    
    end {
        $BaseEnvironmentsConfig
        Write-Verbose -Message "$functionName - END"
    }
  }

  
function Get-CurrentEnvironment {
    <#
    .SYNOPSIS
    Get current environment 
    
   
    .EXAMPLE
     Get-CurrentEnvironmen
  #>
    begin {
         $functionName = $MyInvocation.InvocationName
         Write-Verbose -Message "$functionName - START"   
    }
     process {
            Write-Verbose -Message "Processing $functionName with $Environment Environment." 
            $envConfig = Get-EnvironmentConfig 
            $env = $envConfig.Keys | Where-Object { $envConfig[$_].BatchNode.NodeName -EQ $env:COMPUTERNAME }
     }
    end {
        return $env
        Write-Verbose -Message "$functionName - END"
    }
}

   function Get-WebBackEndNodes {
   <#
       .SYNOPSIS
       # Get WebBackEndNodes servers for given envrionment
   
       .DESCRIPTION
           Read list of WebBackEnd servers for all environments from config and return lis of servers based on given environment
   
       .PARAMETER Environment
           Environment Name 
   
       .PARAMETER ScriptPath
           Script Path ,if ScriptPath provides , Environments.json will read from script path else it will read from Environments.json under PS-Utility folder
   
       .EXAMPLE 
           Get-WebBackEndNodes -Environment SLO6
           Key   Value                             
           ---   -----                             
           SLO6 {VCWQ003165, VCWQ003164}
   
       .NOTES
   #>
       [CmdletBinding()]
       [OutputType('System.Collections.Generic.Dictionary[String,System.Collections.Generic.List[string]]')]
           Param(
               [Parameter(Mandatory=$true)]
               [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PA","PROD_NA","PROD_RW","PROD")]
               [String]$Environment,
               [Parameter(Mandatory=$false)]
               [string]$ScriptPath
               )
       begin{
                $functionName = $MyInvocation.InvocationName
                Write-Verbose -Message "$functionName - START"   
                $WebBackendServers=New-Object 'System.Collections.Generic.Dictionary[String,System.Collections.Generic.List[string]]';  
                 enum Keys{
                            PROD
                            PA
                            SLO
                            WebBackEndNodes
                        }
                $WebBackEndNodes=[string]([Keys]::WebBackEndNodes)
               
           }
       process {
                Write-Verbose -Message "Processing $functionName with $Environment Environment." 
             
                $WebBackendServers.Clear();
                $EnvConfig=Get-EnvironmentConfig  -ScriptPath $ScriptPath          
            
                if($EnvConfig.Contains($Environment)){
                    $env=$EnvConfig[$Environment]
                    $WebBackendServers.Add($Environment,$env[$WebBackEndNodes])
                
                }elseif($Environment.ToUpper() -eq $([Keys]::PROD)){
                    $EnvConfig.Keys  | Where-Object {$_ -like "$([Keys]::PROD)*"} | &{Process{
                        $env=$EnvConfig[$_]
                        $WebBackendServers.Add($_,$env[$WebBackEndNodes])
                    }};
                } elseif($Environment.ToUpper() -eq $([Keys]::PA)){
                    $EnvConfig.Keys  | Where-Object {$_ -like "$([Keys]::SLO)*"} | &{Process{
                        $env=$EnvConfig[$_]
                        $WebBackendServers.Add($_,$env[$WebBackEndNodes])
                  }};
           }
       }
       end {
            $WebBackendServers
            Write-Verbose -Message "$functionName - END"
       }
   }
   
   function Get-BatchNodes {
    <#
    .SYNOPSIS
    Get Batch Node for specific environment
    
    .DESCRIPTION
     Read Environment.json 
    
    .PARAMETER Environment
    Parameter description
    
    .PARAMETER ScriptPath
    Parameter description
    
    .EXAMPLE
     PS > Get-BatchNode -Environment PROD

        Key     Value               
        ---     -----               
        PROD_NA {NodeName, IsActive}
        PROD_RW {NodeName, IsActive}

    .EXAMPLE
        PS >  Get-BatchNode -Environment PROD

        Key  Value               
        ---  -----               
        SLO1 {NodeName, IsActive}
    
    
    #>
    [CmdletBinding()]
    [OutputType("System.Collections.Generic.Dictionary[String,System.Collections.Specialized.OrderedDictionary]")]
    param (
        [Parameter(Mandatory=$true)]
        [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD_NA","PROD_RW","PROD")]
        [String]$Environment,
        [Parameter(Mandatory=$false)]
        [string]$ScriptPath
    )
    begin {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"   
        $BatchNodes=New-Object 'System.Collections.Generic.Dictionary[String,System.Collections.Specialized.OrderedDictionary]';  
         enum Keys{
                    PROD
                    BatchNode
                  }
        $BatchNode=[string]([Keys]::BatchNode)
    }
    process {
        Write-Verbose -Message "Processing $functionName with $Environment Environment." 
             
        $BatchNodes.Clear();
        $EnvConfig=Get-EnvironmentConfig  -ScriptPath $ScriptPath          
    
        if($EnvConfig.Contains($Environment)){
            $env=$EnvConfig[$Environment]
            $BatchNodes.Add($Environment,$env[$BatchNode])
        
        }elseif($Environment.ToUpper() -eq $([Keys]::PROD)){
            $EnvConfig.Keys  | Where-Object {$_ -like "$([Keys]::PROD)*"} | &{Process{
                $env=$EnvConfig[$_]
                $BatchNodes.Add($_,$env[$BatchNode])
            }};
        }
   }
    end {
        $BatchNodes
        Write-Verbose -Message "$functionName - END"
    }
}
  
   function Get-ConfigValues {
   <#
       .SYNOPSIS
       # Get Config Values from AppConfig.json
   
       .DESCRIPTION
           Read list of config values from AppConfig.json if ScriptPath provides , Environments.json will read from script path else it will read from Environments.json under PS-Utility folder
   
       .PARAMETER ScriptPath
           Script Path
   
       .EXAMPLE 
          Get-ConfigValues
   
       .EXAMPLE 
          Get-ConfigValues -ScriptPath $PSScriptRoot
           
   #>
   [CmdletBinding()]
   Param(
     [Parameter(Mandatory=$false)]
     [string]$ScriptPath
       )
       Begin
       {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"
      }
       Process
        { 
            Write-Verbose -Message "Processing $functionName for AppConfig" 

            $AppConfigFile=Join-Path $(Get-UtilityScriptPath) "AppConfig.json"
            $BaseAppConfig= Get-Content -Path $AppConfigFile -Raw -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue `
                                            |ConvertFrom-Json |Convert-ToOrderedDictionary

            if(![string]::IsNullOrWhiteSpace($ScriptPath) -and ( Test-Path $ScriptPath )){
                $AppLevelAppConfigFile=Join-Path $ScriptPath "AppConfig.json"
                $BaseAppConfig= Get-Content -Path $AppLevelAppConfigFile -Raw `
                                                -ErrorAction:SilentlyContinue -WarningAction:SilentlyContinue `
                                                |ConvertFrom-Json |Convert-ToOrderedDictionary   `
                                                |Merge-WithConfig -WithBaseConfig $BaseAppConfig
             }

        }

       end{
            $BaseAppConfig
            Write-Verbose -Message "$functionName - END"
       }
      
   }
   
   function Convert-ToList{
   <#
       .SYNOPSIS
       Convert string to list by using spliter
   
       .PARAMETER strValue
       String value 
   
       .PARAMETER spliter
       Spliter value
   #>
       [CmdletBinding()]
   Param(
       [string] $strValue,
       [string] $spliter
       )
       Begin
       {
           $functionName = $MyInvocation.InvocationName
           Write-Verbose -Message "$functionName - START"
       }
       Process
       {
        Write-Verbose -Message "Processing $functionName with  $strValue value and $spliter spliter"
            $list=  New-Object Collections.Generic.List[String] 
           ( $strValue -split $spliter )| ForEach-Object{if (-not [string]::IsNullOrWhiteSpace($_)){ $list.Add($_);}}
       }
       End {
        $list;
        Write-Verbose -Message "$functionName - END"
       }
   }
   
   function Convert-ToString{
   <#
       .SYNOPSIS
       Convert list to string by using delimiter
   
       .PARAMETER List
       List of string values 
   
       .PARAMETER spliter
        Delimiter value
   
   #>
       [CmdletBinding()]
        Param(
            [Collections.Generic.List[String]] $List,
            [string] $Delimiter
            )
            Begin
            {
                $functionName = $MyInvocation.InvocationName
                Write-Verbose -Message "$functionName - START"
            }
            Process
            {
                Write-Verbose -Message "Processing $functionName with List  and $Delimiter Delimiter"
               if([string]::IsNullOrWhiteSpace($Delimiter)){ $Delimiter = "`n"}
                $result= ""
                  if($List -and $List.Count -gt 0){
                       for ($i=0; $i -lt $List.Count-1; $i++) {$result=$result + $List[$i]   +$Delimiter }
                      $result=$result+ $List[$List.Count-1]
                }
            }
            End {

                $result
                Write-Verbose -Message "$functionName - END"
            }
               
       }    
   
   function New-ItemIfNotExists {
   <#
   .SYNOPSIS
       This helper commandlet helps to create folder\file if not exists 
   
   .PARAMETER Path
       Path of the folder \file 
   
   .PARAMETER ItemType
       ItemType is folder\file
   
   .EXAMPLE
       New-ItemIfNotExists -Path "D:\BatchMonitor\BatchLog" -ItemType Directory
   
   #>
   [CmdletBinding()]
   Param(
       [Parameter(Mandatory=$True)]
       [ValidateNotNullOrEmpty()]        
       [string]$Path,
       [Parameter(Mandatory=$True)]
       [ValidateSet("Directory","File")]
       [string]$ItemType
   )
   Begin
        {
            $functionName = $MyInvocation.InvocationName
            Write-Verbose -Message "$functionName - START"
        }
    Process{
           
            Write-Verbose -Message "Processing $functionName with Path:$Path and ItemType:$ItemType"
            if (!(Test-path $path)){
                New-Item -Path $Path -ItemType $ItemType  -ErrorAction SilentlyContinue  -WarningAction SilentlyContinue
            }
        }
    end {
            $path
            Write-Verbose -Message "$functionName - END"
         }  
   }
   
   function Get-Parent {
   <#
       .SYNOPSIS
       This helper commandlet helps to Get parent folder path
   
       .PARAMETER Path
       Path\location 
   
       .EXAMPLE
       $Parent=Get-Parent  -Path "D:\BatchMonitor\BatchLog"
   
   #>
       [CmdletBinding()]
   param (
           [Parameter(Mandatory=$True)]
           [ValidateNotNullOrEmpty()]   
           [string]$Path
       )
       Begin
       {
           $functionName = $MyInvocation.InvocationName
           Write-Verbose -Message "$functionName - START"
       }
    Process{
        Write-Verbose -Message "Processing $functionName with Path:$Path "
            $result=$Path
            if (Test-path $Path){
                $result= Split-Path $Path  -Parent
            }
    }
    end {
        $result
        Write-Verbose -Message "$functionName - END"
    }  
   }
   
   function Get-UtilityScriptPath {
   <#
       .SYNOPSIS
       Get script path 
   
       .EXAMPLE
       $scriptPath=Get-UtilityScriptPath
   
   #>
   Begin
   {
       $functionName = $MyInvocation.InvocationName
       Write-Verbose -Message "$functionName - START"
   }
   Process{
           
            Write-Verbose -Message "Processing $functionName with Path:$Path and ItemType:$ItemType"
             $scriptPath =$PSScriptRoot
            if ([string]::IsNullOrWhiteSpace($PSScriptRoot) -or !(Test-path $PSScriptRoot)  ){
                $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
        }
   }
   end {
    $scriptPath
    Write-Verbose -Message "$functionName - END"
    }  
}
   function Test-ChangeTransactionID{
   <#
       .SYNOPSIS
       Test ChangeTransactionID whether it is Valid Change ticket\Incident format
   
       .EXAMPLE
        Test-ChangeTransactionID CHG11668794 
   
       .EXAMPLE
        Test-ChangeTransactionID  INC18717230
   
   #>
   [CmdletBinding()]
   param (
           [string]$ChangeTransactionID
       )
       Begin
       {
           $functionName = $MyInvocation.InvocationName
           Write-Verbose -Message "$functionName - START"
       }
       Process{
            Write-Verbose -Message "Processing $functionName with Path:$Path and ItemType:$ItemType"
              $result=$false
                if ($null -eq $ChangeTransactionID){ $result= $false}
                else {
                    $ChangeTransactionID = $ChangeTransactionID.ToUpper()
                    $result= ($ChangeTransactionID  -match  "^[CHG]{3}[0-9]{8}$" -or $ChangeTransactionID  -match  "^[INC]{3}[0-9]{8}$")
                }
      
        }
        end {
            $result
            Write-Verbose -Message "$functionName - END"
        }

}
function Add-DSLOPSModulePath {
    <#
    .SYNOPSIS
    Add DSLO-PSModule Path in Environment Variable
    
    .EXAMPLE
     Add-DSLOPSModulePath
    
    #>
    begin {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"
    }
    process {
        $AppConfigFile=$(Join-Path $(Get-UtilityScriptPath) "AppConfig.json")
        $DSLOPSModulePath= (Get-Content -Path $AppConfigFile -Raw  |ConvertFrom-Json ).DSLOPSModulePath
    
        Write-Verbose "Add DSLO PS-Module path to environment Variable -started"    
         if(!($env:PSModulePath.Contains($DSLOPSModulePath))){
             $PSModulePath=$env:PSModulePath+";$DSLOPSModulePath"
             [Environment]::SetEnvironmentVariable('PSModulePath', $PSModulePath, "Machine")
         }
         Write-Verbose "Add DSLO PS-Module path to environment Variable ended"    
    }
    end {
        $DSLOPSModulePath
        Write-Verbose -Message "$functionName - END"   
    }
}
function Install-DSLOPSModule {
    <#
    .SYNOPSIS
    Install DSLO PS Module in DSLO PS Module path
    
    .PARAMETER ScriptPath
    Script path Where module definition is available 
    
    .EXAMPLE
     Install-DSLOPSModule
    
    .NOTES
    General notes
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true ,HelpMessage="Provide script path where module manifest file is located.")]
        [string]$ScriptPath   
    )
    
    begin {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"
        
        if (!(Test-path $ScriptPath)) {Write-Error "Given Script path $scriptPath doesn't exist. Please provide correct path" return}
    }
    process {

        Write-Verbose "Read Module Manifest -started"    
        (Get-ChildItem  $ScriptPath -Filter "*.psd1" ) | &{Process{
            $ModuleFullName= $_.FullName
            $ModuleConfig = ( Invoke-Expression $(Get-Content  $ModuleFullName | Out-String) )
            Write-Verbose "Read Module Manifest ended."    
            
            $ModuleVersion=$ModuleConfig["ModuleVersion"]
            $ModuleName=$ModuleConfig["RootModule"].Split(".")[0]
            $DSLOPSModule =$(Add-DSLOPSModulePath)
            $ModuleInstalledPath=Join-Path $DSLOPSModule "$ModuleName\$ModuleVersion"
            
            New-ItemIfNotExists   $ModuleInstalledPath  -ItemType Directory
            
            Write-Verbose "Copy files to $ModuleInstalledPath folder -started "    
            $ModuleConfig["FileList"] |&{Process{ 
            $FileName=$_
            $FileName=$FileName.Replace(".\","")
            $FullFileName= (join-path $ScriptPath $FileName)
             Copy-Item  $FullFileName $ModuleInstalledPath -Force}}
            Write-Verbose "Copy files to $ModuleInstalledPath folder -end. "    
            
            Import-Module $ModuleName
        }}
    }
    end {
        Write-Verbose -Message "$functionName - END"
    }
}
