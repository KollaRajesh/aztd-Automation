    <#
.SYNOPSIS
 Restart Computer

 .DESCRIPTION
 Restart local computer if machineName is not provided . 
 Restart computer if machineName is provided and accessible from localhost . 

.EXAMPLE
    Example 1
    
    Restart-Computer

    Example 2 
        
    Restart-Computer LRW1791376
#>
function Restart-Computer {
    [CmdletBinding()]
    param (
        [string] $MachineName
    )
    
    begin {
        $FunctionName= $MyInvocation.InvocationName
        Write-Verbose -Message "$FunctionName - Start"
        [TestNetConnectionResult]$ConnectionResult
    }
    process {
        if ($MachineName){
            $result=$(TNC -ComputerName  $MachineName -CommonTCPPort WINRM   -ErrorAction SilentlyContinue -WarningAction SilentlyContinue)
            if(!( $result.TcpTestSucceeded -and $result.PingSucceeded)){ 
                Write-Verbose "$MachineName is not accessible from  $($env:COMPUTERNAME)"
                return $false;}
        }else {
            $machineName=$env:COMPUTERNAME #Machine name
        }
        
        Restart-Computer -ComputerName $MachineName -AsJob
    }
    
    end {
         Write-Verbose -Message "$FunctionName - End"
    }
}
