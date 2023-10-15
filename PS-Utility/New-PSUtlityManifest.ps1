Function New-PSUtilityManifest{
    $psd1File= join-path $PSScriptRoot "PS-Utility1.psd1"
    $RootModule=  "PS-Utility.psm1"
    
    $manifest = @{
        Path              =$psd1File
        RootModule        =$RootModule 
        Author            = 'Rajesh Kolla'
    }
        New-ModuleManifest @manifest
    }
    
    New-PSUtilityManifest