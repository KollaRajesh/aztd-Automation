### How to connect to List of servers using mstsc\RDP  terminal with saved credentials using PowerShell  

We can prompt window to get credentails of user with the help of `Get-Credentials` commandlet and it will captured password as secureString  `System.Security.SecureString`
 
```powershell
	Get-Credential -UserName $env:UserName -Message 'Please enter password'
```

Alternative way to capature password as secureString  [System.Security.SecureString]

```powershell 
	$pw =Read-Host  "Enter Password"  -AsSecureString
```

`cmdkey` utility is used to add\delete\list domain,generic,smart card & rsa credentials into windows credentials store 

> **Syntax**:
    
```cmd

 <# To list available credentials:#>
     cmdkey /list
     cmdkey /list:targetname

  <# To create domain credentials: #>
     cmdkey /add:targetHostOrIp /user:username /pass:password
     cmdkey /add:targetHostOrIp /user:username
     cmdkey /add:targetHostOrIp /smartcard
     
  <# To create generic credentials:#>
     The /add switch may be replaced by /generic to create generic credentials
     
     cmdkey /generic:targetHostOrIp /user:username /pass:password
     cmdkey /generic:targetHostOrIp /user:username
     cmdkey /generic:targetHostOrIp /smartcard
     
  <# To delete existing credentials:#>
     cmdkey /delete:targetHostOrIp

  <# To delete RAS credentials: #>
     cmdkey /delete /ras
```
>  **Example**
 
```sh
	
    ## Adding generic credentials into windows credential store  for Server1 
    cmdkey /generic:Server1 /user:$userName /pass :$pwd

    ## Adding generic credentials with TERMSRV into windows credential store  for Server2
    cmdkey /generic:TERMSRV/Server1 /user:$userName /pass :$pwd
    
    ##Adding domain credentials into windows credential store  for Server3
    cmdkey /add:Server3 /user:$userName  /pass:$pwd

	##delete saved credentials from windows credential store for Server1
    cmdkey /generic:Server1 
  	
    ##delete saved credentials from windows credential store for Server2
    cmdkey /generic:Server2
    
    ##delete saved credentials from windows credential store for Server3
    cmdkey /generic:Server3 

```

Here is [complete script](../RDP/Connect-WebBEServers.ps1) to connect to list of servers using mstsc terminal with saved credentials using PowerShell.


<!--
References

[enable-saved-credentials-usage-rdp](https://theirbros.com/enable-saved-credentials-usage-rdp/)

[login-to-remove-usingmstsc-with-password](https://stackoverflow.com/questions/14481882/login-to-remove-usingmstsc-admin-with-password/)
## -->