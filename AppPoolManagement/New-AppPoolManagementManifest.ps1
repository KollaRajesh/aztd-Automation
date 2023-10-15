Function New-AppPoolManagementManifest{
    $psd1File= join-path $PSScriptRoot "AppPool-Management.psd1"
    $RootModule=  "AppPool-Management.psm1"
    
    $manifest = @{
        Path              =$psd1File
        RootModule        =$RootModule 
        Author            = 'Rajesh Kolla'
    }
        New-ModuleManifest @manifest
    }
    
    New-AppPoolManagementManifest