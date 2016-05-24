Function IsRunning-AzureRmVm
{
    <#

        .SYNOPSIS

        Check if azure resource manager virtual machine is running.



        .DESCRIPTION

        This function checks, if a an azure resource manager virtual machine is running.



        .PARAMETER AzureResourceGroupName

        The resource group name, containing the virtual machine.


        .PARAMETER AzureVmName

        Name of the virtual machine.



        .EXAMPLE 

        IsRunning-AzureRmVm -AzureResourceGroupName "TestResourceGroup" -AzureVmName "TestVm"

    #>
    Param(  [Parameter(Mandatory=$true)]
            [string]$AzureResourceGroupName,

            [Parameter(Mandatory=$true)]
            [string]$AzureVmName
    )

    [string]$State = Get-AzureRmVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVmName -Status | Select-Object StatusesText

    foreach($String in $State.ToString().Split(',')) {

        if ($String.Contains("Code") -and $String.Contains("running")) 
        {
            return $true
        }
    }

    return $false
}
