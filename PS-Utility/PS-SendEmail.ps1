<# 

    .NOTES
        Script:PS-SendEmail.ps1
        Version :1.0 - initial version
        Author: Rajesh Kolla
        Last Edit: 2023-04-23
        
 #>

 function Send-Email { 
    <#
        .SYNOPSIS
        Send email to give Recipients, CCRecipients
    
    
        .PARAMETER From
        Parameter description
    
        .PARAMETER To
        List of Recipients
    
        .PARAMETER Cc
        List of CcRecipients
    
        .PARAMETER Attachments
        List of Attachments
    
        .PARAMETER Subject
        Subject of the email
    
        .PARAMETER Body
        Body of the email
    
        .EXAMPLE
    
    
        .NOTES
        General notes
    #>  
    [CmdletBinding()]
    Param(
        [string] $Subject,
        [string] $Body,
        [String] $From,
        [Collections.Generic.List[String]] $To,
        [Collections.Generic.List[String]] $Cc,
        [Collections.Generic.List[String]] $Attachments
    
    )
    Begin
    {
        $functionName = $MyInvocation.InvocationName
        Write-Verbose -Message "$functionName - START"
    }
    Process{
            
            Write-Verbose -Message "Processing $functionName"
                    if($null -eq $To -or $To.Count -le 0){ 
                            if($null -eq $Recipients -or $Recipients.Count -le 0){ throw [CustomException]::new("Initialize Send Email functionality.","")}
                        $To=$Recipients
                    }
    
                    if($null -eq $Cc -or $Cc.Count -le 0){ 
                            if($null -eq $CCRecipients -or $CCRecipients.Count -le 0){ throw [CustomException]::new("Initialize Send Email functionality.","")}
                        $Cc=$CCRecipients
                    }
    
                    if([string]::IsNullOrWhiteSpace($From)){ 
                            if( [string]::IsNullOrWhiteSpace($SendFromAddress)){ throw [CustomException]::new("Initialize Logging functionality.","")}
                            $From=$SendFromAddress
                    }
                    
                    Write-Message  -m "Sending Email with $JobName details to $To Team."
                    
                    $TimeStamp = $(Get-Date -Format "yyyy-MM-dd hh:mm:ss")
    
                    if(-not $subject){
                        $subject = "$JobName - Environment:$Environment - $TimeStamp "
                    }
                
                    if(-not $Body){
                        $Body = " Hi 
                                <br\>
                                <p>Please find attached files for $TimeStamp </p>
                                    <ol>
                                        $($Attachments | ForEach-Object {$fileName=(Split-Path  $_ -Leaf); "<li>$fileName</li>"})
                                    </ol>	
                                <br\>
                                &nbsp; - DSLO Team"
                    }
                Send-MailMessage -To $To -Cc $Cc -From $From -Attachments $Attachments -Subject $Subject  -Body $Body -BodyAsHtml  -SmtpServer $SMTPRelay
                
                Write-Message -Message  "Following file(s) are sent to  DSLO-Level1 Team. `n  $(Convert-ToString -List  $Attachments )"
        }
        end {
            Write-Verbose -Message "$functionName - END"
        }
    }
    
    
    function Initialize-SendEmail {
    <#
    .SYNOPSIS
        Initialize Logging functionality
    
    .PARAMETER JobName
    JobName\Script Name to Initialize Logging 
    
    #>
    
    Param(
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [ValidateSet("SLO1","SLO2","SLO3","SLO5","SLO6","PROD_NA","PROD_RW","PROD", "PA")]
        [string]$Environment,
        [Parameter(Mandatory=$false)]
        [string]$ScriptPath
        )
     Begin{
            $functionName = $MyInvocation.InvocationName
            Write-Verbose -Message "$functionName - START"
      }
      Process{
            Write-Verbose -Message "Processing $functionName with Environment:$Environment and ScriptPath:$ScriptPath"
            $ConfigValues= Get-ConfigValues -ScriptPath $ScriptPath
    
            $EMailConfig=$ConfigValues["EMailConfig"]
            $JobName=$ConfigValues["JobName"]
            New-Variable -Name SMTPRelay -Value $($EMailConfig["SMTPRelay"]) -Scope Script -Force
            New-Variable -Name SendFromAddress -Value $($EMailConfig["SendFromAddress"]) -Scope Script -Force
            New-Variable -Name Recipients -Value $(Convert-ToList -strValue $EMailConfig["Recipients"]  -spliter ";") -Scope Script -Force
            New-Variable -Name CCRecipients -Value $(Convert-ToList -strValue $EMailConfig["CCRecipients"]  -spliter ";") -Scope Script -Force
            New-Variable -Name JobName -Value $JobName -Scope Script -Force
            New-Variable -Name Environment -Value $Environment -Scope Script -Force
      }
       end {
            Write-Verbose -Message "$functionName - END"
       }
     }