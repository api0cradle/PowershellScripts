<#
.Synopsis
    Script to document checksum of WIMs. Finds all wims in specified folder and runs checksum of them and write it to a ChecksumDBFile.
    Script generates eventlog results. Information event if nothing has changed and Error if the checksum has changed since last run.
    
    The script creates a WIMHash source in the eventlog. If you want to remove the WIMHash source from the eventlog run this command:
    Remove-EventLog -Source WIMHash

.DESCRIPTION
    Created: 05.01.2016
    Version: 0.9
    
    Author: Oddvar Moe
    Blog: http://msitpros.com 
    Twitter: @oddvarmoe

    Disclaimer: I take no responsebility if you choose to use this script. 
    Always test before putting into production. 
    The script is provided "AS IS" with no warranties.
.EXAMPLE
    Just run the script - No parameters needed. The variables is hard-coded inside the script.  
#>

$MDTShare = "D:\ImageFactory\boot"
$ChecksumDBFile = "D:\CheckSumDB.csv"
$Wims = get-childitem -path $MDTShare -Recurse -Include *.wim
$table = @{}

#Check if you are running elevated
If (-NOT ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(`
    [Security.Principal.WindowsBuiltInRole] "Administrator"))
{
    Write-Warning "Script needs an elevated PowerShell prompt!`nStart PowerShell as an Administrator and run the script again."
	Write-Warning "Script is aborted"
    Break
}

#Check if Eventlog is ready
If([System.Diagnostics.EventLog]::SourceExists("WIMHash") -eq $False){
    #Create the Source in Eventlog
    new-eventlog -LogName Application -Source WIMHash
}

$Wims | 
    foreach{
        $FullName = $_.FullName
        $hash = Get-FileHash -path $_.FullName-Algorithm MD5
                
        $properties = @{'FullName'=$_.FullName;
                        'Hash'=$hash.Hash;
                        'Algorithm'=$hash.Algorithm;
                        'Date'= (get-date)}
        
        $output = New-Object -TypeName PSObject -Property $properties
        
        #Check to verify if the ChecksumDBFile contains data 
        if([bool]($ChecksumCSV = import-csv $ChecksumDBFile)){
            
            #Check to verify that File Full Name is found inside the ChecksumDBFile 
            if($ChecksumCSV -like "*$FullName*"){
                
                #Select only lines that is relevant to filename and select the latest unique entry in the CSV
                $Unique = $ChecksumCSV | where{$_.FullName -like "*$FullName*"} | Sort-Object -Property Date -Descending | Select-object -First 1 | Select-Object Hash
                
                #Compare Hash from ChecksumDBFile with Hash from the wim file               
                if($Unique.Hash -like $hash.Hash){
                    Write-EventLog -LogName Application -Source WIMHash -EntryType Information -EventId 1 -Message "The hash of the file $FullName has not changed since last run. `n Current hash is: $hash"
                }else{
                    write-eventlog -LogName Application -Source WIMHash -EntryType Error -EventId 1 -Message "The file $FullName has a changed Checksum since last run, someone did something! `n Last hash from ChecksumDBFile: $Unique `n Current hash of file is: $Hash"
                }
             }
        }else{
            #CSV does not exists - probably first time run or file is deleted
            write-eventlog -LogName Application -Source WIMHash -EntryType Information -EventId 1 -Message "The CSV file did not exist or is empty. Writing to new file. `n ChecksumDBFile: $ChecksumDBFile"
        }
    $output | Export-csv $ChecksumDBFile -Append
    }

