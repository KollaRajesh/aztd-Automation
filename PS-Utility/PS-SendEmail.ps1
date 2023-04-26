<#
   .Notes
     Script: PS-SendEmail.ps1
     Version: Initial Version V(1.0.0)
     Author: Rajesh Kolla 
     Last Edit: 2023-04-24
#>
function Initialize-SendEmail {
<#
    .SYNOPSIS
    Initialize configuration and variables for Send Email functionality.
#>
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [string]$JobName,
    [parameter(Mandatory=$true)]
    [ValidateNotNullOrEmpty()]
    [ValidateSet("Test1","Test2","Test3","Test5","Test6","QA","PROD_NonDR","PROD_DR","PROD")]
    [parameter(Mandatory=$false)]
    [string] $ScriptPath
  )

  process {
     $ConfigValues = Get-ConfigValues -ScriptPath $ScriptPath 
     $EmailConfig =$ConfigValues.$EmailConfig
     New-Variable  -Name SMTPRelay -Value $($EmailConfig.SMTPRelay)  -Scope Script -Force
     New-Variable  -Name SendFromAddress -Value $($EmailConfig.SendFromAddress) -Scope Script -Force
     New-Variable  -Name Recipients -Value $(Convert-ToList -strValue $EmailConfig.Recipients -Spliter ";") -Scope Script -Force
     New-Variable  -Name CCRecipients -Value $(Convert-ToList -strValue $EmailConfig.CCRecipients -Spliter ";") -Scope Script -Force
     New-Variable  -Name JobName -Value $JobName -Scope Script -Force
     New-Variable  -Name Environment -Value $Environment -Scope Script -Force
  }
}

function Send-Email {
  [CmdletBinding()]
  param(
    [parameter(Mandatory=$false,HelpMessage ="Please specify subject of the email.")]
    [string] $Subject,
    [parameter(Mandatory=$false,HelpMessage ="Please specify body of the email.")]
    [string] $Body,
    [parameter(Mandatory=$false,HelpMessage ="Please specify From Email Id")]
    [string] $From,
    [parameter(Mandatory=$false,HelpMessage ="List of  Recipients email ids")]
    [System.Collections.Generic.List[String]] $To,
    [parameter(Mandatory=$false,HelpMessage ="List of CC Recipients email ids")]
    [System.Collections.Generic.List[String]] $CC,
    [parameter(Mandatory=$false,HelpMessage ="Please provide list of full path for attachments")]
    [System.Collections.Generic.List[String]] $Attachments
  )
 begin{
    if($null -eq $To -or $To.Count -le 0){
        if ($null -eq $Recipients -or $Recipients.Count -le 0 ) {
            throw [System.CustomException]::New("Initialize send email functionality or provide To Receipient list","")
            break;
        }
       $To=$Recipients
       
    }

    if($null -eq $CC -or $CC.Count -le 0){
        if ($null -eq $CCRecipients -or $CCRecipients.Count -le 0 ) {
            throw [System.CustomException]::New("Initialize send email functionality or provide CC Receipient list","")
            break;
        }
       $CC=$CCRecipients
    }
    if([string]::IsNullOrWhiteSpace($From)){
        if ([string]::IsNullOrWhiteSpace($SendFromAddress)) {
            throw [System.CustomException]::New("Initialize send email functionality or provide From Address.","")
            break;
        }
       $From=SendFromAddress
    }
    $TimeStamp =$(Get-Date -Format "yyyy-MM-dd hh:mm:ss")
 
    if (-not $Subject){
        $Subject ="$JobName -Environment:$Environment -$TimeStamp"
       }
       $Team="<Team Name>"
       if (-not $Body){
        $Body ="Hi 
                <br\> 
                <p> Please find attached file(s) for $TimeStamp </p>
                <ol>
                $($Attachments |ForEach-Object {$fileName=(Split-Path $_ -Leaf);"<li>$fileName </li>" })
                </ol>
                <br\> 
                &nbsp; -$Team Team"
       }

 }
  process {
    Write-Message -m "Sending Email with $JobName details to $Team Team."   
    Send-MailMessage -To $To -Cc $CC -From $From -Attachments $Attachments -Subject $Subject -Body $Body  -BodyAsHtml -SmtpServer $SMTPRelay
  }
  end{
    Write-Message -m "Following file(s) are sent to $Team Team `n $(Convert-ToString -List $Attachments)"
  }
}