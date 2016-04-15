Function AzCopy-BlobCopy()
{    
    Param(  [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$BlobName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$SourceSubscription,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$SourceResourceGroupName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$SourceStorageAccountName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$SourceStorageAccountContainerName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$DestinationSubscription,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$DestinationResourceGroupName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$DestinationStorageAccountName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$DestinationStorageAccountContainerName
    )
    
    $AzCopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"

    $SourceContext = Get-AzureRmContext

    if ($SourceContext.Subscription.SubscriptionName -ine $SourceSubscription)
    {
        # Request user login
        $Credential = Get-Credential -Message "Provide username and password."
        
        # Login into source subscription
        $SourceContext = Login-AzureRmAccount -Credential $Credential -SubscriptionName $SourceSubscription

        if (!$SourceContext)
        {
            # End if login fails
            return    
        }
    }

    # Get source storage account key
    $SourceKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $SourceResourceGroupName -Name $SourceStorageAccountName).Key1 

    # Login into destination subscription
    if ($SourceSubscription -ine $DestinationSubscription)
    {
        $DestinationContext = Login-AzureRmAccount -Credential $Credential -SubscriptionName $DestinationSubscription

        if(!$DestinationContext)
        {
            # End if login fails
            return
        }
    }

    # Get Destination Storage Account Key #
    $DestinationKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $DestinationResourceGroupName -Name $DestinationStorageAccountName).Key1

    # Copy the blob #    
    & $AzCopyPath "/Source:https://$($SourceStorageAccountName).blob.core.windows.net/$($SourceStorageAccountContainerName)/",`
                  "/Dest:https://$($DestinationStorageAccountName).blob.core.windows.net/$($DestinationStorageAccountContainerName)/",`
                  "/Pattern:$($BlobName)",` 
                  "/DestKey:$($DestinationKey)",` 
                  "/SourceKey:$($SourceKey)"
}
