Function AzureVm-IsRunning
{
    Param([string]$AzureResourceGroupName,
          [string]$AzureVmName
    )

    [string]$State = Get-AzureRmVM -ResourceGroupName $AzureResourceGroupName -Name $AzureVmName -Status | Select-Object StatusesText

    foreach($String in $State.ToString().Split(',')) {

        if ($String.Contains("Code") -and $String.Contains("running")) {

            return $true

        }
    }

    return $false
}
