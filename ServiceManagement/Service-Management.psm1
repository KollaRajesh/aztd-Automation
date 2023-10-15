<# 

    .NOTES
        Script:PS-Utility.psm1
        Version :1.0 - initial version
        Author: Rajesh Kolla
        Last Edit: 2023-04-23
        
 #>
 $exportsPath =$PSScriptRoot
if($exportsPath) {
    Get-ChildItem -Path $exportsPath -File -Filter "*.ps1" |  ForEach-Object { . $_.FullName }
    Export-ModuleMember -Function Invoke-ServiceAction
}





