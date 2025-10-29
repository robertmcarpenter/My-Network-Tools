<#############################################
##    Written by Robert Carpenter (E7873)   ##
##     for Desktop Support Services         ##
##             Field Projects               ##
##                                          ##
##                                          ##
##                                          ##
##############################################>


function Get-SubnetHostnames {
    param(
        [string]$Subnet,
        [int]$StartRange,
        [int]$EndRange
    )
    $startTime = Get-Date
    for ($i = $StartRange; $i -le $EndRange; $i++) {
        #Progress Bar code 
        $elapsed = (New-TimeSpan -Start $startTime).TotalSeconds
        $averageItemTime = $elapsed / $i
        $remainingItems = $EndRange - $i
        $secondsRemaining = $remainingItems * $averageItemTime
        Write-Progress -Activity "Pinging ALL devices on this branch subnet. Check $($branch_code.ToUpper())-PingReport.txt for results." -Status "IP $i of $EndRange" -PercentComplete (($i / $EndRange) * 100) -SecondsRemaining $secondsRemaining
        $ipAddress = "$Subnet.$i"
        
        try {
            #Checking with the DNS Server to see if Device even exists on the subnet. If there is no DNS name for the device registered then it does not exist.
            $hostname = [System.Net.Dns]::GetHostEntry($ipAddress).Hostname
            #This Logic is to find out if the hostname starts with DT or LT. If it is, then do a AD lookup to get the XXXX-TLR# format instead of dtxxxxxxxxxx####
            if( ($hostname.Length -ge 2) -and (($hostname.ToLower().Substring(0,2) -eq "dt") -or ($hostname.ToLower().Substring(0,2) -eq "lt")) ) {
                 #Credit to Jacob Van Essendelft  for this AD lookup snippet
                 $adComputer = Get-ADComputer -Filter {DNSHostName -eq $hostname} -Properties Description
                 $hostname = $adComputer.Description
            }
            $device = "$ipAddress - $hostname"
            #If Else block for successful and failed pings
            if(Test-Connection -Count 1 -Quiet $ipAddress){
                $result = "Ping to $ipAddress - $hostname SUCCESS. Device is online and replying."
                Write-Host $result -ForegroundColor Green
                #Add this device to an array for reporting later 
                $success.Add($device) | Out-Null

        
            }
            else {
              $result = Write-Host "Ping to $ipAddress - $hostname FAILED. Please check this device!" -ForegroundColor Red
              Write-Host $result -ForegroundColor Red 
              $failed.Add($device) | Out-Null
            }
        } catch {
            Write-Output "$ipAddress doesn't exist on this subnet. Moving to the next IP..." 
        }
    }
    Write-Progress -Activity "Pinging ALL devices on this branch subnet. Check $branch_code-PingReport.txt for results." -Status "Complete!" -Completed
}

$asciiart = @"
 ,,,,,    .,,,,,,,.  ,*@*.   ,,,   ,,,,,,,,,,,,,   :@@;    ,,,,,,       -;+,    
,@@@@@@&, ;@@@@@@@-.@@@@@@& ,@@* ,@@@;,@@@@@@@@* *@@@@@@@  &@@@@@@*  ,H@@&@&@&. 
,@@+ -@@@ ;@@:     +@@, -@*,,@@*-@@@,    .@@*   :@@*  ;@@+ &@& .@@@.;*.*.:,.::+,
,@@+  +@@,;@@@@@@& .@@@@&+. ,@@@@@@,     .@@*   @@@.   &@& &@&  @@@.:; ; :. + **
,@@+  ;@@-;@@@&&&&   +@@@@@-,@@@@@@@.    .@@*   @@@    &@& &@@@@@@*:++;*;*;;&:@*
,@@+  @@@.;@@:     ::+  ,@@*,@@@:-@@&    .@@*   *@@,  .@@@ &@@++;, --: : :. + +:
,@@@@@@@@ ;@@@@@@@;*@@+.+@@:,@@*  *@@*   .@@*   .@@@*+@@@- &@&      *&*&*@@*&@&+
,@@@@@&:  ;@@@@@@@; *@@@@&: ,@@*   &@@;  .@@*     @@@@@&.  &@&       *@:,:,;,@+ 
                                                                      .@H*+H*   
                                                                                
.@*@@.@- *&,@@@@.@@@@.@@@@+,@@@@+&@@@&  *@*@;*@@@@+@@@@.@: +&;@.@@@@;+@@@@-@*@* 
.@&*,.@- *&,@:;@,@;:@;@, ;@-@@@@; -@.   *@@; *@&&*+@@@@.@@ &;;@,@-   +@&&*:@@+. 
,:.;@.@: @&,@@*:.@@*:-@- +@-@:&@  -@.   --.@@*&   +@-@* .@;@ ;@,@: +++@   -:.*& 
 &@&@ *@@&-,@-  .@:   +&@&-,@: @@ -@.   ;&@&:*@@@@+@.-@; @@+ ;@.;&@&-+@@@&,&@&+ 
::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
 ____  ___  _   _   ____                                             
|  _ \|_ _|| \ | | / ___|                                            
| |_) || | |  \| || |  _                                             
|  __/ | | | |\  || |_| |                                            
|_|___|___||_|_\_|_\____|___ __   __ _____  _   _  ___  _   _   ____ 
| ____|\ \   / /| ____||  _ \\ \ / /|_   _|| | | ||_ _|| \ | | / ___|
|  _|   \ \ / / |  _|  | |_) |\ V /   | |  | |_| | | | |  \| || |  _ 
| |___   \ V /  | |___ |  _ <  | |    | |  |  _  | | | | |\  || |_| |
|_____| __\_/  _|_____||_| \_\ |_|    |_|  |_| |_||___||_| \_| \____|
|_   _|/ _ \  / _ \ | |                                              
  | | | | | || | | || |                                              
  | | | |_| || |_| || |___                                           
  |_|  \___/  \___/ |_____|  

"@

Write-Host $asciiart
# SCRIPT STARTS HERE
Write-Host "Enter the 5 digit branch code. This will be used to run the tool and create the report:  " -ForegroundColor Yellow -NoNewLine
$branch_code = Read-Host 
$switch_hostname = "sw-" + $branch_code.ToLower() + "-1"
$ip = [System.Net.Dns]::GetHostAddresses( $switch_hostname).IPAddressToString
$octets = $ip.Split('.')
$subnet = ($octets[0], $octets[1], $octets[2]) -join '.'

$report = "{0}-PingReport.txt" -f ($branch_code.ToUpper())
$success = New-Object System.Collections.ArrayList
$failed = New-Object System.Collections.ArrayList
$startRange = 1
$endRange = 254
$totalItems = $endRange - $startRange

Get-SubnetHostnames -Subnet $subnet -StartRange $startRange -EndRange $endRange


#Generate the .txt report
Write-Host "Report for $($branch_code.ToUpper()) ran on $(Get-Date)" -ForegroundColor Yellow 
"Report for $($branch_code.ToUpper()) ran on $(Get-Date)"| Out-File $report

Write-Output "`nHere's all the online devices:" | Tee-Object $report -Append

#Iterate through all of the succeeded items and print them out to the console + report.txt
$success_file_buffer = 
  ForEach ($item in $success) {
        Write-Output $item
    }

Start-Sleep -Seconds 1.5
$success_file_buffer | Tee-Object $report -Append
#This Sleep is to avoid a race condition where the script proceeds but doesn't close the file in time 
Start-Sleep -Seconds 1.5


Write-Output "`nHere's all the FAILED devices:" | Tee-Object $report -Append

$failed_file_buffer = 
  ForEach ($item in $failed) {
        Write-Output $item
    }
Start-Sleep -Seconds 1.5
$failed_file_buffer | Tee-Object $report -Append

#This Sleep is to avoid a race condition where the script proceeds but doesn't close the file in time 
Start-Sleep -Seconds 1.5
Read-Host -Prompt "`nTool is finished running. Please check $report (same directory you ran the script in) for summary. Press Enter to exit."
