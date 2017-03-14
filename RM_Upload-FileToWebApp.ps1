Function Get-AzureRmWebAppPublishCredentials
{
    <#

    .SYNOPSIS

    Gets publish credentials for authentication with kudu engine.
    For more information about kudu see LINK section.



    .DESCRIPTION

    This function gets the publish credentials for interaction with kudu engine.



    .PARAMETER ResourceGroupName
    
    Name of the resource group containing the azure web app. 


    .PARAMETER WebAppName

    Name of the web app.


    .PARAMETER SlotName 

    The slot name to upload the file to. Not mandatory.



    .EXAMPLE 

    Upload a file to wwwroot.

    Get-KuduApiAuthorisationToken $Token.Properties.PublishingUserName $Token.Properties.PublishingPassword



    .NOTES

    Required in Upload-FileToWebApp.



    .LINK
    
    https://github.com/projectkudu/kudu

    #>

    Param([ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$ResourceGroupName,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$WebAppName,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$False)]
          [string]$SlotName
    )

	if ([string]::IsNullOrWhiteSpace($SlotName))
    {
		$ResourceType = "Microsoft.Web/sites/config"
		$ResourceName = "$WebAppName/publishingcredentials"
	}
	else
    {
		$ResourceType = "Microsoft.Web/sites/slots/config"
		$ResourceName = "$WebAppName/$SlotName/publishingcredentials"
	}

	$PublishCredentials = Invoke-AzureRmResourceAction -ResourceGroupName $ResourceGroupName `
                                                        -ResourceType $ResourceType `
                                                        -ResourceName $ResourceName `
                                                        -Action list `
                                                        -ApiVersion 2015-08-01 `
                                                        -Force
    
    return $PublishCredentials
}

Function Get-KuduApiAuthorizationToken
{
    <#

    .SYNOPSIS

    Creates the authorization header for authentication with kudu engine.
    For more information about kudu see LINK section.


    .DESCRIPTION

    This function creates the authentication header for requesting publish credentials for interaction with kudu engine.


    .PARAMETER Username
    
    User login name. 


    .PARAMETER password

    User password.


    .EXAMPLE 

    Get-KuduApiAuthorizationToken -Username "User1" -Password "123456"


    .NOTES

    Required in Upload-FileToWebApp.


    .LINK
    
    https://github.com/projectkudu/kudu

    #>

    Param([ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$Username,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$Password
    )

    return ("Basic {0}" -f [Convert]::ToBase64String([Text.Encoding]::ASCII.GetBytes(("{0}:{1}" -f $Username, $Password))))
}

Function Upload-FileToWebApp
{
    <#

    .SYNOPSIS

    Uploads local files to azure web apps via kudu engine.


    .DESCRIPTION


    This function uploads a local file to an azure web app via the kudu engine. The kudu path can be outside wwwroot. 
    For more information about kudu see LINK section below.


    .PARAMETER WebAppName 

    Name of the azure web app.


    .PARAMETER ResourceGroupName
    
    Name of the resource group containing the azure web app. 


    .PARAMETER SlotName 

    The slot name to upload the file to. Not mandatory.


    .PARAMETER KuduPath

    The path to upload the file to. Paths outside wwwroot are possible.


    .PARAMETER LocalPath

    The full qualified path on your local system to upload the file from.


    .EXAMPLE 

    Upload a file to wwwroot.

    Upload-FileToWebApp -WebAppName "DemoWebApp" -ResourceGroupName "DemoWebAppRG" -KuduPath "site/wwwroot/bin/test.json" -LocalPath "C:\tmp\test.json"


    .EXAMPLE 

    Upload a file outside wwwroot.

    Upload-FileToWebApp -WebAppName "DemoWebApp" -ResourceGroupName "DemoWebAppRG" -KuduPath "data/functions/test.json" -LocalPath "C:\tmp\test.json"


    .NOTES

    Requires Get-AzureRmWebAppPublishCredentials and Get-KuduApiAuthorisationToken.


    .LINK
    
    https://github.com/projectkudu/kudu

    #>

    Param([ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$WebAppName,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$ResourceGroupName,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$False)]
          [string]$SlotName,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$KuduPath,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$LocalPath
    )

    $Token = Get-AzureRmWebAppPublishCredentials -resourceGroupName $ResourceGroupName -webAppName $WebAppName

    $KuduApiAuthorizationToken = Get-KuduApiAuthorizationToken -Username $Token.Properties.PublishingUserName -Password $Token.Properties.PublishingPassword    

    if ($SlotName -eq "")
    {
        $KuduApiUrl = "https://$WebAppName.scm.azurewebsites.net/api/vfs/$KuduPath"
    }
    else
    {
        $KuduApiUrl = "https://$WebAppName`-$SlotName.scm.azurewebsites.net/api/vfs/$KuduPath"
    }

    $VirtualPath = $KuduApiUrl.Replace(".scm.azurewebsites.", ".azurewebsites.").Replace("/api/vfs/site/wwwroot", "")
    
    Write-Host " Uploading File to WebApp. Source: '$LocalPath'. Target: '$VirtualPath'..."  -ForegroundColor DarkGray

    Invoke-RestMethod -Uri $KuduApiUrl `
                        -Headers @{"Authorization"=$KuduApiAuthorizationToken;"If-Match"="*"} `
                        -Method PUT `
                        -InFile $LocalPath `
                        -ContentType "multipart/form-data"
}


$AzureSubscription = "<YOUR SUBSCRIPTION NAME>"
$LoginName = "<YOUR LOGIN NAME>"
$ResourceGroupName = "<YOUR RESOURCE GROUP NAME>"
$WebAppName = "<YOUR WEBAPP NAME>"
$KuduFilePath = "<PATH TO KUDU FILE>"
$LocalFilePath = "<LOCAL FILE PATH>"

$Credential = Get-Credential -UserName $LoginName -Message "Provide password for user: '$LoginName'"
Login-AzureRmAccount -SubscriptionName $AzureSubscription -Credential $Credential

Upload-FileToWebApp -WebAppName $webAppName -ResourceGroupName $ResourceGroupName -KuduPath $KuduFilePath -LocalPath $LocalFilePath
