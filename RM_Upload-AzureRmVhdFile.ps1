Function Upload-AzureRmVhdFile
{
    <#

        .SYNOPSIS

        Upload vhd file to azure resource manager.



        .DESCRIPTION

        This function uploads a local vhd file containing an image to azure resource manager resource group.



        .PARAMETER SubscriptionName

        Name of the azure subscription to upload the vhd file to.


        .PARAMETER ResourceGroupName

        Name of the azure resource group to upload the vhd file to.


        .PARAMETER UploadURI

        The uri pointing to the azure storage account container to upload the file to.


        .PARAMETER LocalVhdPath

        Local path to the vhd file.



        .EXAMPLE 

        Upload-AzureRmVhdFile -SubscriptionName "TestSubscrition" -ResourceGroupName "TestResourceGroup" -UploadURI "https://teststorage.blob.core.windows.net/vhds" -LocalVhdPath "c:\test.vhd"

    #>

    Param([Parameter(Mandatory=$true)]
          $SubscriptionName,

          [Parameter(Mandatory=$true)]
          $ResourceGroupName,

          [Parameter(Mandatory=$true)]
          $UploadURI,

          [Parameter(Mandatory=$true)]
          $LocalVhdPath
    
    )

    $SubscriptionName = "<Subscription name>"
    $ResourceGroupName = "<Resource group name>"
    $UploadURI = "<URI to vhd file>"
    $LocalVhdPath = "<Local path to vhd file>"

    Login-AzureRmAccount -Credential (Get-Credential -Message "Provide user name and password.") -SubscriptionName $SubscriptionName

    Add-AzureRmVhd -ResourceGroupName $ResourceGroupName -Destination $UploadURI -LocalFilePath $LocalVhdPath -NumberOfUploaderThreads 10
}
