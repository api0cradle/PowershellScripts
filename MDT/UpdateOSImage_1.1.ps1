# Auto update OS Image
# Author: Oddvar Moe - msitpros.com
# Require: PowerCLI from Vmware
# Require: You need to copy litetouchpe_x86 iso to the correct datastore on vmware
# Require: Change $PSEmailServer and $EmailFrom in Sendmail function

$Mailto = "your.account@customer.com"

$isopath = "[VMware_Datastore.0] ISO\LiteTouchPE_x86.iso"
$networkname = "Customer-network"
$resourcepool = "HA Cluster"

$MDTOSFolder = "E:\Deploymentshare\Operating Systems\Windows 10 X64 Enterprise - Deployment Image"
$MDTBuilOSdFolder = "E:\BuildDeployment\Captures"


# Function to ADD PowerCli as module
function Import-PowerCLI {
	Add-PSSnapin vmware*
	if (Get-Item 'C:\Program Files (x86)' -ErrorAction SilentlyContinue) {
		. "C:\Program Files (x86)\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
	}
	else {
		. "C:\Program Files\VMware\Infrastructure\vSphere PowerCLI\Scripts\Initialize-PowerCLIEnvironment.ps1"
	}
}

function SendMail{
param(
[string]$emailto
)

[string]$PSEmailServer = "Exchange.customer.com"
[string]$EmailFrom = "MDT <MDT@customer.com>"

[string]$emailbody = @"
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
    </head>
<body>
Hi.<br>
A new image has been created and has been added to the deployment solution. 
<br>
<br><br>
Best regards
<br>
MDT Powershell script


</body>
</html>
"@

Send-MailMessage -To $emailto -Subject "MDT image was updated" -Body $emailbody -From $EmailFrom -Priority Normal -SmtpServer $PSEmailServer -encoding UTF8 -BodyAsHtml
}

#### SCRIPT STARTS HERE ####
Import-PowerCLI

#Remove all WIMs before starting
get-childitem $MDTBuilOSdFolder | remove-item

# Connect to virtual center and start VM
Connect-VIServer -Server 192.168.100.10

new-vm -name "AUTOMDTOSDBUILD" -DiskMB 60000 -MemoryMB 6000 -ResourcePool $resourcepool -Version v8 -numCpu 2 -GuestID "windows8_64Guest"
get-vm -Name "AUTOMDTOSDBUILD" | get-networkadapter | Set-NetworkAdapter -NetworkName $networkname -type "E1000" -Confirm:$false
$cd = New-CDDrive -VM "AUTOMDTOSDBUILD" -ISOPath $isopath
Set-CDDrive -CD $cd -StartConnected $true -Confirm:$false
Start-VM -VM "AUTOMDTOSDBUILD"

$VM = get-vm -name "AUTOMDTOSDBUILD"

while ((get-vm -name "AUTOMDTOSDBUILD").PowerState -eq "PoweredOn")
{
    write-host "Still deploying and alive - pausing script for 180 seconds - be patient" -ForegroundColor Green
    sleep 180
}

#Remove the VM
Remove-VM -VM "AUTOMDTOSDBUILD" -DeletePermanently -Confirm:$false

#Check for WIM file and replace it
$NewWim = Get-childItem $MDTBuilOSdFolder
if($NewWim){move-item $NewWim.FullName $MDTOSFolder -force}

#Send mail when done
SendMail -emailto $Mailto
