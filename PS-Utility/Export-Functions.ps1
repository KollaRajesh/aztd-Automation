<#
   .Notes
     Script: Export-Functions.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>

function Test-FunctionName {
    [CmdletBinding()]
    [OutputType("boolean")]
<#
.SYNOPSIS
 Test function is valid or not 
.PARAMETER Name
Name of the function
#>
    Param(
    [Parameter(Position = 0,Mandatory,HelpMessage = "Specify a function name.")]
    [ValidateNotNullOrEmpty()]
    [string]$Name
    )
    process {
    Write-Verbose "Validating function name $Name"
    #Function name must first follow Verb-Noun pattern
    if ($Name -match "^\w+-\w+$") {
        #validate the standard verb
        $verb = ($Name -split "-")[0]
        Write-Verbose "Validating detected verb $verb"
        if ((Get-Verb).verb -contains $verb ) {
            $True
        }
        else {
            Write-Verbose "$($Verb.ToUpper()) is not an approved verb."
            $False
        }
    }
    else {
        Write-Verbose "$Name does not match the regex pattern ^\w+-\w+$"
        $False
    }
}
}

Function Export-FunctionFromFile {
    [cmdletbinding(SupportsShouldProcess)]
    [alias("eff")]
    [OutputType("None", "System.IO.FileInfo")]
<#
.SYNOPSIS
 Export function from File

.PARAMETER Path
Path

.PARAMETER OutputPath
OutputPath

.PARAMETER All
All

.PARAMETER Passthru
Passthru

#>
    Param(
        [Parameter(Position = 0, Mandatory, HelpMessage = "Specify the .ps1 or .psm1 file with defined functions.")]
        [ValidateScript({
                If (Test-Path $_ ) {
                    $True
                }
                Else {
                    Throw "Can't validate that $_ exists. Please verify and try again."
                    $False
                }
            })]
        [ValidateScript({
                If ($_ -match "\.ps(m)?1$") {
                    $True
                }
                Else {
                    Throw "The path must be to a .ps1 or .psm1 file."
                    $False
                }
            })]
        [string]$Path,
        [Parameter(HelpMessage = "Specify the output path. The default is the same directory as the .ps1 file.")]
        [ValidateScript({ Test-Path $_ })]
        [string]$OutputPath,
        [Parameter(HelpMessage = "Export all detected functions.")]
        [switch]$All,
        [Parameter(HelpMessage = "Pass the output file to the pipeline.")]
        [switch]$Passthru
    )
    Write-Verbose "Starting $($MyInvocation.MyCommand)"

    #always create these variables
    New-Variable astTokens -Force -WhatIf:$False
    New-Variable astErr -Force -WhatIf:$False

    if (-Not $OutputPath) {
        #use the parent path of the file unless the user specifies a different path
        $OutputPath = Split-Path -Path $Path -Parent
    }

    Write-Verbose "Processing $path for functions"
    #the file will always be parsed regardless of WhatIfPreference
    $AST = [System.Management.Automation.Language.Parser]::ParseFile($Path, [ref]$astTokens, [ref]$astErr)

    #parse out functions using the AST
    $functions = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    if ($functions.count -gt 0) {
        Write-Verbose "Found $($functions.count) functions"
        Write-Verbose "Creating files in $outputpath"
        Foreach ($item in $functions) {
            Write-Verbose "Detected function $($item.name)"
            #only export functions with standard namees or if -All is detected.
            if ($All -OR (Test-FunctionName -name $item.name)) {
                $newfile = Join-Path -Path $OutputPath -ChildPath "$($item.name).ps1"
                Write-Verbose "Creating new file $newFile"
                Set-Content -Path $newFile -Value $item.ToString() -Force
                if ($Passthru -AND (-Not $WhatIfPreference)) {
                    Get-Item -Path $newfile
                }
            }
            else {
                Write-Verbose "Skipping $($item.name)"
            }
        } #foreach item
    }
    else {
        Write-Warning "No functions detected in $Path."
    }
    Write-Verbose "Ending $($MyInvocation.MyCommand)"
} 

function Export-FunctionFromScripts{
<#
.SYNOPSIS
 Export functions from scripts in $PSScriptRoot folder
#>
  Process{
        if($PSScriptRoot){
            $exportScript =$PSScriptRoot
            $exportedFunctions=Join-Path $exportScript "Exported-Functions"
            New-ItemIfNotExists -Path $ExportecFunctions -ItemType Directory
            
            Get-ChildItem -Path $exportScript -File -Filter "*.ps1" `
            | Where-Object {$_.Name -notin @("Export-Functions.ps1","New-PSUtilityManifest.ps1")}  `
            | ForEach-Object { Export-FunctionFromFile -Path $_.FullName -Passthru -OutputPath $exportedFunctions}

            <# Get-ChildItem -Path $exportScript -File -Recurse -Include "*.ps1" -Exclude "Export-Functions.ps1","New-PSUtilityManifest.ps1" `
            | &{Process { Export-FunctionFromFile -Path $_.FullName -Passthru -OutputPath $exportedFunctions}};#>
         }
    }
}

Export-FunctionFromScripts 