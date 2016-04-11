$SubscriptionName = "<Subscription name>"
$ResourceGroupName = "<Resource group name>"
$UploadURI = "<URI to vhd file>"
$LocalVhdPath = "<Local path to vhd file>"

Login-AzureRmAccount -Credential (Get-Credential -Message "Provide user name and password.") -SubscriptionName $SubscriptionName

Add-AzureRmVhd -ResourceGroupName $ResourceGroupName -Destination $UploadURI -LocalFilePath $LocalVhdPath -NumberOfUploaderThreads 10
