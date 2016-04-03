<#
 Author: Oddvar Moe [MVP]
 Webpage: http://msitpros.com
 
 Disables RC4 Windows servers
 Requires Hotfix on olders server os (pre 2012R2)
 https://support.microsoft.com/en-us/kb/2868725 

 Disables SSL3.0, SSL2.0 and TLS1.0
 Both Client and Server side
#>

#Check if you are running elevated 
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "You need to run this script from an elevated PowerShell prompt!`nPlease start the Script as an Administrator"
    Break
}

#### Disable RC4 ####
Write-host "Disabling RC4 Ciphers"
$RC4CipherRootKey = "HKLM:\SYSTEM\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Ciphers\"
# $([char]0x2215) in order to have / in name
$Keyname1 = "RC4 56$([char]0x2215)128"
$Keyname2 = "RC4 40$([char]0x2215)128"
$Keyname3 = "RC4 128$([char]0x2215)128"

New-Item $RC4CipherRootKey$Keyname1 -Force
New-Item $RC4CipherRootKey$Keyname2 -Force
New-Item $RC4CipherRootKey$Keyname3 -Force


Set-ItemProperty $RC4CipherRootKey$Keyname1 -Name Enabled -Value 0 -Type Dword
Set-ItemProperty $RC4CipherRootKey$Keyname2 -Name Enabled -Value 0 -Type Dword
Set-ItemProperty $RC4CipherRootKey$Keyname3 -Name Enabled -Value 0 -Type Dword
#### End Disable RC4 ####


#### Disable SSL3.0 ####
write-host "Disabling SSL3.0 protocol"
$SSL3MainKey = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 3.0"

New-Item "$SSL3MainKey\Client\" -Force
Set-ItemProperty "$SSL3MainKey\Client\" -Name "DisabledByDefault" -Value 1 -Type Dword

New-Item "$SSL3MainKey\Server\" -Force
Set-ItemProperty "$SSL3MainKey\Server\" -Name "Enabled" -Value 0 -Type Dword
#### End Disable SSL3.0 ####


#### Disable SSL2.0 ####
write-host "Disabling SSL2.0 protocol"
$SSL2MainKey = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\SSL 2.0"

New-Item "$SSL2MainKey\Client\" -Force
Set-ItemProperty "$SSL2MainKey\Client\" -Name "DisabledByDefault" -Value 1 -Type Dword

New-Item "$SSL2MainKey\Server\" -Force
Set-ItemProperty "$SSL2MainKey\Server\" -Name "Enabled" -Value 0 -Type Dword
#### End Disable SSL2.0 ####


#### Disable TLS1.0 ####
write-host "Disabling TLS1.0 protocol"
$TLS1MainKey = "HKLM:\System\CurrentControlSet\Control\SecurityProviders\SCHANNEL\Protocols\TLS 1.0"

New-Item "$TLS1MainKey\Client\" -Force
Set-ItemProperty "$TLS1MainKey\Client\" -Name "DisabledByDefault" -Value 1 -Type Dword

New-Item "$TLS1MainKey\Server\" -Force
Set-ItemProperty "$TLS1MainKey\Server\" -Name "Enabled" -Value 0 -Type Dword
#### End Disable TLS1.0 ####
Write-host "Done!"
