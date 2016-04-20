Function AzCopy-BlobCopy()
{    
    <#

    .SYNOPSIS

    Copies blobs inside azure, or downloads a blob to local file, or viceversa.



    .DESCRIPTION


    The AzCopy-BlobCopy function uses Azcopy to copy blobs inside Azure (including copying into other subscriptions). It also supports download of blobs and Upload of files into a blob. The
    
    copy process runs asynchronously. For more information about AzCopy see link at the end of this help.



    .PARAMETER Copy 

    Switch to start a copy process inside azure.


    .PARAMETER Download
    
    Switch to start a copy process that downloads a blob from azure into a local file. 


    .PARAMETER Upload 

    Switch to start a copy process that uploads a local file to an azure blob.


    .PARAMETER BlobName

    The name of the blob to be copied. Name is not changeable during copy process. Source and Destination blob have always the same name.


    .PARAMETER SourceSubscription

    The name of the source subscription, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Download.


    .PARAMETER SourceResourceGroupName

    The name of the source resource group name, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Download.


    .PARAMETER SourceStorageAccountName

    The name of the source storage account name, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Download.


    .PARAMETER SourceStorageAccountContainerName

    The name of the source storage account container name, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Download.


    .PARAMETER DestinationSubscription

    The name of the destination subscription, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Upload.


    .PARAMETER DestinationResourceGroupName

    The name of the destination resource group name, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Upload.


    .PARAMETER DestinationStorageAccountName

    The name of the destination storage account name, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Upload.


    .PARAMETER DestinationStorageAccountContainerName

    The name of the destination storage account container name, to copy the blob from. Optional parameter, only valid with switch -Copy, or -Upload.


    .PARAMETER LocalPath

    The local path, to copy the blob from, or to (without file name). Optional parameter, only valid with switch -Download, or -Upload.



    .EXAMPLE 

    Copy a blob from one azure subscription into another one.

    AzCopy-BlobCopy -Copy `
                -BlobName "TestVm1.vhd" `
                -SourceSubscription "Subscription 1" `
                -SourceResourceGroupName "DefaultResourcegroup" `
                -SourceStorageAccountName "scs2635467wgt7893300033" `
                -SourceStorageAccountContainerName "vhds" `
                -DestinationSubscription "Subscription 2" `
                -DestinationResourceGroupName "NewResourceGroup" `
                -DestinationStorageAccountName "2367gfstorageaccount" `
                -DestinationStorageAccountContainerName "vhds"


    .EXAMPLE 

    Copy a blob from azure to a local file.

    AzCopy-BlobCopy -Download `
                -BlobName "TestVm1.vhd" `
                -SourceSubscription "Subscription 1" `
                -SourceResourceGroupName "DefaultResourcegroup" `
                -SourceStorageAccountName "scs2635467wgt7893300033" `
                -SourceStorageAccountContainerName "vhds" `
                -LocalPath "C:\test\"


    .EXAMPLE 

    Copy a local file into an azure blob.

    AzCopy-BlobCopy -Upload `
                -BlobName "TestVm1.vhd" `
                -LocalPath "C:\test\"
                -DestinationSubscription "Subscription 2" `
                -DestinationResourceGroupName "NewResourceGroup" `
                -DestinationStorageAccountName "2367gfstorageaccount" `
                -DestinationStorageAccountContainerName "vhds"


    .NOTES

    This function includes login into azure, if context is not already present.


    .LINK
    
    https://azure.microsoft.com/de-de/documentation/articles/storage-use-azcopy/ 

    #>

    Param(  
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [switch]$Copy,

            [Parameter(Mandatory=$True, ParameterSetName="Download")]
            [switch]$Download,

            [Parameter(Mandatory=$True, ParameterSetName="Upload")]
            [switch]$Upload,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True)]
            [string]$BlobName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Download")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$SourceSubscription,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Download")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$SourceResourceGroupName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Download")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$SourceStorageAccountName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Download")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$SourceStorageAccountContainerName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Upload")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$DestinationSubscription,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Upload")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$DestinationResourceGroupName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Upload")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$DestinationStorageAccountName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Upload")]
            [Parameter(Mandatory=$True, ParameterSetName="Copy")]
            [string]$DestinationStorageAccountContainerName,

            [ValidateNotNullOrEmpty()]
            [Parameter(Mandatory=$True, ParameterSetName="Upload")]
            [Parameter(Mandatory=$True, ParameterSetName="Download")]
            [string]$LocalPath
    )
    
    $AzCopyPath = "C:\Program Files (x86)\Microsoft SDKs\Azure\AzCopy\AzCopy.exe"
    $ArgSource = "/Source:$($LocalPath)"
    $ArgSourceKey = ""
    $ArgDest = "/Dest:$($LocalPath)"
    $ArgDestKey = ""

    $SourceContext = Get-AzureRmContext -ErrorAction SilentlyContinue

    # Check if already logged in
    if (!$SourceContext)
    {
        # Request user login
        $Credential = Get-Credential -Message "Provide username and password."

        $Subscription = $SourceSubscription

        if (!$Subscription)
        {
            $Subscription = $DestinationSubscription
        }

        # Login into source subscription
        $SourceContext = Login-AzureRmAccount -Credential $Credential -SubscriptionName $Subscription
    }

    if ($Download -or $Copy)
    {
        # Select source subscription
        Select-AzureRmSubscription -SubscriptionName $SourceSubscription

        if (!$?)
        {
            # End if selection fails
            return    
        }

        # Get source storage account key
        $SourceKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $SourceResourceGroupName -Name $SourceStorageAccountName).Key1 

        if (!$SourceKey)
        {
            $SourceKey = (Get-AzureStorageKey -StorageAccountName $SourceStorageAccountName -ErrorAction SilentlyContinue).Primary
        }

        $ArgSource = "/Source:https://$($SourceStorageAccountName).blob.core.windows.net/$($SourceStorageAccountContainerName)/"
        $ArgSourceKey = "/SourceKey:$($SourceKey)"
    }

    if ($Upload -or $Copy)
    {
        # Select destination subscription
        Select-AzureRmSubscription -SubscriptionName $DestinationSubscription

        if (!$?)
        {
            # End if selection fails
            return    
        }

        # Get Destination Storage Account Key
        $DestinationKey = (Get-AzureRmStorageAccountKey -ResourceGroupName $DestinationResourceGroupName -Name $DestinationStorageAccountName -ErrorAction SilentlyContinue).Key1

        if (!$DestinationKey)
        {
            $DestinationKey = (Get-AzureStorageKey -StorageAccountName $DestinationStorageAccountName -ErrorAction SilentlyContinue).Primary
        }

        $ArgDest = "/Dest:https://$($DestinationStorageAccountName).blob.core.windows.net/$($DestinationStorageAccountContainerName)/"
        $ArgDestKey = "/DestKey:$($DestinationKey)"
    }

    # Copy the blob   
    & $AzCopyPath $ArgSource, $ArgDest, "/Pattern:$($BlobName)", $ArgDestKey, $ArgSourceKey
}
