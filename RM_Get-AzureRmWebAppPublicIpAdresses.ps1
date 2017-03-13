Function Get-AzureRmWebAppPublicIpAdresses
{
    <#

    .SYNOPSIS

    Gets a list of all puböic ip adresses of a given azure webapp.


    .DESCRIPTION

    Get-AzureRmWebAppPublicIpAdresses function retrieves all public ip adresses that a asinged to an azure webapp.


    .PARAMETER ResourceGroupName 

    Name of the resourcegroup, containing the app.


    .PARAMETER WebAppName
    
    Name of the webb app to get the public ips from. 


    .EXAMPLE 

    Get-AzureRmWebAppPublicIpAdresses -ResourceGroupName "DemoResourceGroup" -WebAppName "DemoWebApp"


    .NOTES

    This function includes login into azure.


    #>

    Param([ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$ResourceGroupName,

          [ValidateNotNullOrEmpty()]
          [Parameter(Mandatory=$True)]
          [string]$WebAppName
         
         )

    (Get-AzureRmResource -ResourceGroupName $ResourceGroupName -ResourceType "Microsoft.Web/sites" -ResourceName $WebAppName).Properties.OutboundIpAddresses -Split "," 
}

$Subscription = "<YOUR AZURE SUBSCRIPTION NAME>";
$ResourceGroupName = "<YOUR RESOURCEGROUP NAME>"
$ResourceName = "<YOUR WEBAPP NAME>"

Login-AzureRmAccount -Credential (Get-Credential -Message "Provide login credentials.") -SubscriptionName $Subscription

Get-AzureRmWebAppPublicIpAdresses -ResourceGroupName $ResourceGroupName -WebAppName $ResourceName
