<#
   .Notes
     Script: Connect-Servers.psm1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-26
#>
function Export-Members{
    $exportPath= $PSScriptRoot
    if($exportPath){
    Get-ChildItem -Path $exportPath -File -Filter "*.PS1" `
    | ForEach-Object { . $_.FullName}

    Export-ModuleMember -Function Connect-Servers

  }
}
Export-Members