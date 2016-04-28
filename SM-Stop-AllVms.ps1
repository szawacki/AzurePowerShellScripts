workflow Stop-AllVms
{
    <#

        .SYNOPSIS

        Stop all virtual machines.



        .DESCRIPTION

        Workflow to stop all virtual machines of a cloud service in azure service manager.



        .NOTES
        Create a new runbook in your automation account.
        Copy this script into your runbook.
        Provide subscription name, cloud service name and credential for login, in lines 25-27.
        Create a time schedule and assign it to the runbook.
            
    #>

    $Subscription = "<Subscription name>"
    $ServiceName = "<Cloud service name>"
    $Cred = Get-AutomationPSCredential -Name "<credential>"
    
    Add-AzureAccount -Credential $Cred
    Select-AzureSubscription -SubscriptionName $Subscription
    $runningVMs = (Get-AzureVM | where {$_.ServiceName -eq $ServiceName -and $_.Status -ne "StoppedDeallocated"})

    foreach ($VM in $runningVMs) 
    {
        Write-Output "$(Get-Date) - Stopping VM $($VM.Name) ..."
        $stopRtn = Stop-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -Force
        $count=1

        if(($stopRtn.OperationStatus) -ne 'Succeeded')
        {
           do {
                  Write-Output "$(Get-Date) - Failed to stop $($VM.Name). Retrying in 30 seconds..."
                  sleep 30
                  $stopRtn = Stop-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName  -Force
                  $count++
              }
            while(($stopRtn.OperationStatus) -ne 'Succeeded' -and $count -lt 3)         
        }
           
        if($stopRtn) 
        {
            Write-Output "$(Get-Date) - Stop-AzureVM cmdlet for $($VM.Name) $($stopRtn.OperationStatus) on attempt number $count of 3."
        }
    }
}
