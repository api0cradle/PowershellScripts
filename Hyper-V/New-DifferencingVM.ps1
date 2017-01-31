function New-DifferencingVM
<#
.SYNOPSIS

   Function to create a Virtual machine based on a parent vhd - aka differencing disk.
   NOTE - Default ParentVHD paths are hard-coded. These must be either changed manually or you need to specify -parentvhd
   
   Author: Oddvar Moe
   Required Dependencies: Hyper-v module

.DESCRIPTION

   Function to create a Virtual machine based on a parent vhd - aka differencing disk
   NOTE - Default ParentVHD paths are hard-coded. These must be either changed manually or you need to specify -parentvhd

.EXAMPLE
   New-DifferencingVM -VMName Customer1 -VMLocation "D:\VirtualMachines" -VMNetwork EXT-Wireless -VMOS Windows10 -VMMemory 2048MB -VMDiskSize 60GB
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

        [Parameter(Mandatory=$false,ParameterSetName="ParentVHDPath")]
        $ParentVHD,

        #A valid format is 2048MB, Default is 2048MB
        [Parameter(Mandatory=$false)]
        $VMMemory=2048MB,

        #A valid format is 60GB
        [Parameter(Mandatory=$false)]
        $VMDiskSize=60GB,

        #Option to select VM Generation
        [Parameter(Mandatory=$false)]
        [ValidateSet("1","2")]
        $VMGeneration = "1"
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
                $ParentVHD = "D:\HYPERV-MasterImages\Win10Ent1607x64MasterDisk\Win10Ent1607x64MasterDisk.vhdx"
            }

            if($VMOS -eq "Server2012R2")
            {
                $ParentVHD = "D:\HYPERV-MasterImages\Server2012R2\Server2012R2.vhdx"
            }
        }

        try
        {
            New-VM -Name $VMName -MemoryStartupBytes $VMMemory -SwitchName $VMNetwork -Path $VMLocation -NoVHD -Generation $VMGeneration
            New-VHD -ParentPath $ParentVHD -Differencing -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx" -SizeBytes $VMDiskSize
            Add-VMHardDiskDrive -VMName $VMName -Path "$VMLocation\$VMName\Virtual Hard Disks\$VMName-Disk1.vhdx"

            #Correct boot order on Gen2 VMs
            if ($VMGeneration -eq "2") {
                Set-VMFirmware $VMName -BootOrder (Get-VMHardDiskDrive $VMName),(Get-VMNetworkAdapter $VMName)
            }
        }
        catch
        {
            return $_.Exception.Message
        }
        finally
        {
        }
    }
    End
    {
    }
}