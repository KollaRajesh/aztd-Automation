function Get-AssemblyDetails
{
    <#
    .SYNOPSIS
        Get Details of Assemblies in the given path
    .DESCRIPTION
        Get details of assemblies in the given path using reflection.

    .PARAMETER Path
        location of assemblies with wild cards
   .PARAMETER LiteralPath
        location of assemblies with out wild cards
    .INPUTS
        path for assemblies 
    .OUTPUTS 
       Return hashtable with Assembly name as key and  List of Assembly details as value.
    .NOTES
        Program: Get-AssemblyDetails.ps1
        Author: Rajesh Kolla
        Date: 07/31/2023

    .Example  
      
      $list=gci  -Path "C:\AppPath\bin\  -Filter "*.dll" -Recurse|Get-AssemblyDetails
      $list.Keys 
      $Key=$list.Keys[0]
      [hashtable]$list[$Key]
#>
    [CmdletBinding(DefaultParameterSetName="Path")]
    param(
        [Parameter(Mandatory=$true,
                    Position=0,
                    ParameterSetName="Path",
                    ValueFromPipeline=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $Path,
   
        [Alias("PSPath")]
        [Parameter(Mandatory=$true,
                    Position=0,
                    ParameterSetName="LiteralPath",
                    ValueFromPipelineByPropertyName=$true)]
        [ValidateNotNullOrEmpty()]
        [string[]]
        $LiteralPath
    )
    Begin
    {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
        $PathIntrinsics = [System.Management.Automation.PathIntrinsics]$ExecutionContext.SessionState.Path 
        $resultTable = New-Object System.Collections.Hashtable
     }
    Process
    {
        Write-Verbose -Message "$FunctionName - processing"
       if ($psCmdlet.ParameterSetName -eq "Path")
       {
                $resolvedPaths = @()
           # In the non-literal case we may need to resolve a wildcarded path
            foreach ($apath in $Path){
                $resolvedPaths += @(Resolve-Path $apath | &{Process { $_.Path }})
            }
       }
       else {  $resolvedPaths = $LiteralPath }
        
       $resolvedPaths |&{Process {
                             $rpath=$_
                        if ($PathIntrinsics.IsProviderQualified($rpath)){
                            $rpath = $PathIntrinsics.GetUnresolvedProviderPathFromPSPath( $rpath)  }

                            $assemblyInfo = Get-AssemblyInformation -AssemblyFile $rpath
                        
                            if( $assemblyInfo -and !$resultTable.ContainsKey($assemblyInfo.Name)){
                                $resultTable.Add($assemblyInfo.Name ,$assemblyInfo)
                            }
                        }}
    }
    end{
        $resultTable
        Write-Verbose -Message "$FunctionName - End"
    }
 }

function Get-AssemblyCustomAttributes{
 <#
    .SYNOPSIS
        Get Custome Attributes of Assembly
    .DESCRIPTION
        Get custom attributes of assembly 
    .PARAMETER assembly
        aseembly
   .PARAMETER TypeNameLike
        Type Name like 
    .PARAMETER Property
        
    .INPUTS
        path for assemblies 
    .OUTPUTS 
       Return value of the custom attribute 
    
    .Example  
     $Title = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Title' -Property 'Title'   
#>
    param
    (
        [System.Reflection.Assembly] $assembly,
        [string]$TypeNameLike,
        [string]$Property = $null
    )
    Begin
    {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
        $value = $null
    }
    Process
    {
        Write-Verbose -Message "$FunctionName - processing"
        try
        {
            foreach ($attribute in $assembly.GetCustomAttributes($false) )
            {
                if ($attribute.GetType().ToString() -like "*$TypeNameLike*")
                {
                    if ($null -ne $Property)
                    {
                        # Select-Object -ExpandProperty fails if property value is $null
                        try {
                            $value = $attribute | Select-Object -ExpandProperty $Property
                        }
                        catch {
                            $value = $null
                        }
                    }
                    else
                    {
                        $value = $attribute
                    }
                    break;
                }
            }
        } Catch {
          $message= "Exception Occured while getting custom attributes: "+ $_.Exception.Message
           Write-Verbose   $message
        }
    }
end{
     $value
     Write-Verbose -Message "$FunctionName - End"
  }
}
 
function Get-AssemblyInfoAsHashtable {
    param
    (
    [System.Reflection.Assembly] $assembly
    )
    Begin
    {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
    }
    Process
    {
        Write-Verbose -Message "$FunctionName - processing"
        $assemblyHash = @{}

        $assemblyName=[Reflection.AssemblyName]::GetAssemblyName($assembly.Location)
        $assemblyHash.FullName =$assemblyName.FullName
        $assemblyHash.Name = $assembly.ManifestModule.Name
        $assemblyHash.FileVersion=$assemblyName.FileVersion
        $assemblyHash.Version=$assemblyName.Version
        $assemblyHash.Location = $assembly.Location
        $assemblyHash.ImageRuntimeVersion = $assembly.ImageRuntimeVersion
        $assemblyHash.GlobalAssemblyCache = $assembly.GlobalAssemblyCache  
        $assemblyHash.Title = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Title' -Property 'Title'   
        $assemblyHash.Authors = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Authors' -Property 'Authors'
        $assemblyHash.Company = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Company' -Property 'Company'
        $assemblyHash.PackageDescription = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'PackageDescription' -Property 'PackageDescription'  
        $assemblyHash.Configuration = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Configuration' -Property 'Configuration'
        $assemblyHash.Description = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Description' -Property 'Description'#>
        $assemblyHash.Product = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Product' -Property 'Product'
        $assemblyHash.Copyright = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Copyright' -Property 'Copyright'
        $assemblyHash.Trademark = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'Trademark' -Property 'Trademark'
        $assemblyHash.DelaySign = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'DelaySign' -Property 'DelaySign'
        $assemblyHash.KeyName = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'KeyName' -Property 'KeyName'
        $assemblyHash.ClsCompliant = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'ClsCompliant' -Property 'IsCompliant'
        $assemblyHash.ComVisible = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'ComVisible' -Property 'Value'
        $assemblyHash.IsJITTrackingEnabled = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'System.Diagnostics.DebuggableAttribute' -Property 'IsJITTrackingEnabled'
        $assemblyHash.IsJITOptimizerDisabled = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'System.Diagnostics.DebuggableAttribute' -Property 'IsJITOptimizerDisabled'
        $assemblyHash.DebuggingFlags = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'System.Diagnostics.DebuggableAttribute' -Property 'DebuggingFlags'
        $assemblyHash.CompilationRelaxations = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'CompilationRelaxations' -Property 'CompilationRelaxations'
        $assemblyHash.WrapNonExceptionThrows = Get-AssemblyCustomAttributes -Assembly $assembly -TypeNameLike 'System.Runtime.CompilerServices.RuntimeCompatibilityAttribute' -Property 'WrapNonExceptionThrows'
    
    }
    end {
        $assemblyHash
        Write-Verbose -Message "$FunctionName - End"
    }
}
function Get-AssemblyInformation{
param
(
    $AssemblyFile
)
Begin
    {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
        $info = @{}
    }
 Process
    {
        Write-Verbose -Message "$FunctionName - processing"
    
    $info.FullName = $AssemblyFile;
    $info.Name = Split-Path -Path $AssemblyFile -Leaf;
    $info.IsValidDotNetAssembly = $false
    
    try{
        $assembly  =[Reflection.Assembly]::LoadFile($AssemblyFile)

        $info = Get-AssemblyInfoAsHashtable -assembly $assembly
        $info.IsValidDotNetAssembly  = $true
    }
    catch [System.BadImageFormatException] {

                # If a BadImageFormatException is thrown, the file is not an assembly
              $message= "The file is not a .NET assembly : " + $_.Exception.Message
              Write-Verbose $message
              }
     Catch [System.IO.FileNotFoundException]{
                $message="Could not load reference file or assembly : " + $_.Exception.Message
             Write-Verbose   $message
             $info.IsValidDotNetAssembly =$true
     }
    catch { 
        $message=  "Exception Occured while loading file :"  +$_.Exception.Message
       Write-Verbose $message
    }
}
end {    
        $info
        Write-Verbose -Message "$FunctionName - End"
    }

}

<#
    #Usage
      $list=gci  -Path "C:\AppPath\bin\  -Filter "*.dll" -Recurse|Get-AssemblyDetails
    
      [hashtable]$list["AppPackage.dll"]
#>