function New-DifferencingVM
<#
.Synopsis
   Function to create a Virtual machine based on a master vhd - aka differencing disk.
   Author: Oddvar Moe
   Required Dependencies: Hyper-v module
.DESCRIPTION
   Function to create a Virtual machine based on a master vhd - aka differencing disk
.EXAMPLE
   New-DifferencingVM -VMName Kundetest1 -VMLocation "D:\VirtualMachines" -VMNetwork EXT-Wireless -VMOS Windows10 -VMMemory 2048MB -VMDiskSize 60GB
#>
{
    [CmdletBinding(DefaultParameterSetName="VMOS")] 
    [Alias()]
    [OutputType([int])]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        $VMName,
        
        [Parameter(Mandatory=$true,ParameterSetName="VMOS")]
        [ValidateSet("Windows10","Server2012R2")]
        $VMOS,

        [Parameter(Mandatory=$false)]
        $VMLocation="D:\VirtualMachines",

        [Parameter(Mandatory=$false,ParameterSetName="MasterVHDPath")]
        $MasterVHD,
        
        #A valid format is 2048MB, Default is 2048MB
        [Parameter(Mandatory=$false)]
        $VMMemory=2048MB,
    
        #A valid format is 60GB
        [Parameter(Mandatory=$false)]
        $VMDiskSize=60GB
    )
    DynamicParam
    {
        # Sets the dynamic parameters name
        $ParameterName = 'VMNetwork'
 
        # Create a dictionary
        $RuntimeParameterDictionary = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
 
        # Create a collection of attributes
        $AttributeCollection = New-Object System.Collections.ObjectModel.Collection[System.Attribute]
 
        # Create and set the parameters' attributes
        $ParameterAttribute = New-Object System.Management.Automation.ParameterAttribute
        $ParameterAttribute.ValueFromPipeline = $true
        $ParameterAttribute.ValueFromPipelineByPropertyName = $true
        $ParameterAttribute.Mandatory = $true
 
        # Add the attributes to the attributes collection
        $AttributeCollection.Add($ParameterAttribute)
 
        # Generate and set the ValidateSet
        $arrSet = (Get-VMSwitch).Name
        $ValidateSetAttribute = New-Object System.Management.Automation.ValidateSetAttribute($arrSet)
 
        # Add the ValidateSet to the attributes collection
        $AttributeCollection.Add($ValidateSetAttribute)
 
        # Create and return the dynamic parameter
        $RuntimeParameter = New-Object System.Management.Automation.RuntimeDefinedParameter($ParameterName, [string], $AttributeCollection)
        $RuntimeParameterDictionary.Add($ParameterName, $RuntimeParameter)
        return $RuntimeParameterDictionary
    }

    Begin
    {
        #To bind the dynamic parameter to a variable
        $VMNetwork = $PsBoundParameters[$ParameterName]
    }
    Process
    {
        if ($PSCmdlet.ParameterSetName -eq "VMOS") {
            if($VMOS -eq "Windows10")
            {
                #Client
                $MasterVHD = "D:\HYPERV-MasterImages\Win10Ent1607x64MasterDisk\Win10Ent1607x64MasterDisk.vhdx"
            }
    
            if($VMOS -eq "Server2012R2")
            {
                $MasterVHD = "D:\HYPERV-MasterImages\Server2012R2\MDT-MasterServer\Virtual Hard Disks\MDT-MasterServer-Disk1.vhdx"
            }
        }
    
        try
        {
            New-VM -Name $VMName -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Verbose
            New-VHD -ParentPath $MasterVHD -Differencing -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize -Verbose
            Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -Verbose
        }
        catch
        {
            Write-Host "Was not able to do my stuff"
            Write-Error $_.Exception.Message
        }
        finally
        {
        }
    }
    End
    {
    }
}
