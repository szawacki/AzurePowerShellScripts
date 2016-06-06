workflow Start-AllVms
{
    <#

        .SYNOPSIS

        Start all virtual machines.


        .DESCRIPTION

        Workflow to start all virtual machines of a cloud service in azure service manager.


        .NOTES
        
        Create a new runbook in your automation account.
        Copy this script into your runbook.
        Provide subscription name, cloud service name an credential for login, in lines 23-25.
        Create a time schedule and assign it to the runbook.

    #>
    $Subscription = "<Subscription name>"
    $ServiceName = "<Cloud service name>"
    $Cred = Get-AutomationPSCredential -Name "<credential>"
    
    Add-AzureAccount -Credential $Cred 
    Select-AzureSubscription -SubscriptionName $Subscription
    $stoppedVMs = (Get-AzureVM | where {$_.ServiceName -eq $ServiceName -and $_.Status -like "Stopped*"})

    foreach ($VM in $stoppedVMs) {
        Write-Output "$(Get-Date) - Starting VM $($VM.Name) ..."
        $startRtn = Start-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName -ea SilentlyContinue
        $count=1
        if(($startRtn.OperationStatus) -ne 'Succeeded')
          {
           do{
              Write-Output "$(Get-Date) - Failed to start $($VM.Name). Retrying in 30 seconds..."
              sleep 30
              $startRtn = Start-AzureVM -Name $VM.Name -ServiceName $VM.ServiceName  -ea SilentlyContinue
              $count++
              }
            while(($startRtn.OperationStatus) -ne 'Succeeded' -and $count -lt 3)        
       }
           
        if($startRtn) 
        {
            Write-Output "$(Get-Date) - Start-AzureVM cmdlet for $($VM.Name) $($startRtn.OperationStatus) on attempt number $count of 3."
        }
    }
}
