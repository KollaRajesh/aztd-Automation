Function New-ServiceManagementManifest{
    $psd1File= join-path $PSScriptRoot "Service-Management.psd1"
    $RootModule=  "Service-Management.psm1"
    
    $manifest = @{
        Path              =$psd1File
        RootModule        =$RootModule 
        Author            = 'Rajesh Kolla'
    }
        New-ModuleManifest @manifest
    }
  New-ServiceManagementManifest