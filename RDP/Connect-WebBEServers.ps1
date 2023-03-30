
## 1. Server host names should be replaced with actual servers in adding into webBackendActiveServers
## 2. DR Server host Names should be replaced with actual servers in adding into webBackendDRServers

$webBackendServers=New-Object Collections.Generic.List[String]
$webBackendActiveServers=New-Object Collections.Generic.List[String]
$webBackendDRServers=New-Object Collections.Generic.List[String]

$webBackendActiveServers.AddRange([string[]]@("BE-Server1","BE-Server2","BE-Server3","BE-Server4","BE-Server5","BE-Server6"))
$webBackendDRServers.AddRange([string[]]@("BE-DR-Server1","BE-DR-Server2","BE-DR-Server3","BE-DR-Server4","BE-DR-Server5","BE-DR-Server6"))

$credentials = Get-Credential -UserName $env:UserName -Message 'Please enter password'

$userName =$credentials.UserName
$credentials.Password
$pwd=$credentials.GetNetworkCredential().Password

$webBackendServers.AddRange($webBackendActiveServers)
$webBackendServers.AddRange($webBackendDRServers)

$webBackendServers | Foreach-Object {
    ## Adding credentials into windows credential store  for hostname 
    cmdkey /generic:$_ /user:$userName /pass :$pwd

    ##If above command doesn't work then try with below command to add credentials into windows credential store  for hostname 
    ##cmdkey /generic:TERMSRV/$_ /user:$userName /pass :$pwd
    
    ##If above two command don't work then try with below command to add credentials into windows credential store  for hostname 
    ##cmdkey /add:$_ /user:$userName  /pass:$pwd
    mstsc /v:$_ /f

    }

$remove =cmdkey  /list | &{Process {if ($_ -like "*Target=*" -and $webBackendServers.Contains($_.Split("=")[1].Trim())){
$_.Split("=")[1].Trim()}}};

$remove| &{Process {
        
    ## clearing credentials from  windows credential store for hostname 
        cmdkey /delete:$_
        
        ##if use TERMSRV while adding credentials into windows credentials store then uncomment below line of code
        ##cmdkey /delete:TERMSRV/$_}
        };

