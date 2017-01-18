Function Remove-VirtualMachine
<#
.Synopsis
   Function to remove Virtual machine and files. Gets VM names dynamically.
   Author: Oddvar Moe
   Required Dependencies: Hyper-v module
.DESCRIPTION
   Function to remove Virtual machine and files. Gets VM names dynamically.
.EXAMPLE
   PS C:\> Remove-VirtualMachine -VMName AAA -Verbose

   Removes the virtual machine named AAA 
#>
{
    [CmdletBinding()]
    Param()
    DynamicParam
    {
        # Sets the dynamic parameters name
        $ParameterName = 'VMName'
 
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
        $arrSet = (Get-Vm).Name
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
        $VMName = $PsBoundParameters[$ParameterName]
    }
    Process
    {
        try
        {
            $VM = Get-VM -Name $VMName
            $disks = Get-VHD -VMId $vm.Id
            
            Write-Verbose "Removing snapshots if any"
            Remove-VMSnapshot -VMName $VMName –IncludeAllChildSnapshots
            Write-Verbose "Removing virtual harddrive"
            Remove-Item $disks.path -Force
            Write-Verbose "Removing VM"
            Remove-vm -Name $VMName -Force
            Write-Verbose "Removing VM files and folders"
            Remove-item -path $VM.path -Recurse -force
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