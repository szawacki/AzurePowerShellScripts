 [CmdletBinding()]
 Param( [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$AzureSubscription,
               
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$ResourceGroupName,
       
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$VmName,

        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$PublicIpName,
       
        [Parameter(Mandatory=$true)]
        [ValidateNotNullOrEmpty()]
        [string]$NewDomainLable,

        [Parameter(Mandatory=$false)]
        [string]$Username
 )

Function SetNewDomainLable()
{
    Param(  [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$ResourceGroupName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$PublicIpName,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]
            [string]$NewDomainLable
    )

    # Get public IP
    $PublicIP = Get-AzureRmPublicIpAddress -Name $PublicIpName -ResourceGroupName $ResourceGroupName

    if ($PublicIP.DnsSettings.DomainNameLabel -ine $NewDomainLable)
    {
        # chnage domain name lable
        Write-Host "Set new domain lable '$($NewDomainLable)'"
        $PublicIP.DnsSettings.DomainNameLabel = $NewDomainLable.ToLower()
        # Set public IP    
        Set-AzureRmPublicIpAddress -PublicIpAddress $PublicIP
    }
}

Function GetRdpFile()
{
    Param(  [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$ResourceGroupName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$PublicIpName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$VirtualComputerName,

            [Parameter(Mandatory=$false)] 
            [string]$VirtualComputerUsername
    )

    $RdpFilePath = "$($env:USERPROFILE)\Downloads\$($VirtualComputerName).rdp"
    # Get rdp file
    Get-AzureRmRemoteDesktopFile -ResourceGroupName $ResourceGroupName -Name $VirtualComputerName -LocalPath $RdpFilePath

    # Set new FQDN to rdp file
    $Content = [System.IO.File]::ReadAllText($RdpFilePath) -ireplace 'full address:s:.+', "full address:s:$((Get-AzureRmPublicIpAddress -ResourceGroupName $ResourceGroupName -Name $PublicIpName).DnsSettings.Fqdn)"
    [System.IO.File]::WriteAllText($RdpFilePath, $Content)

    if ($VirtualComputerUsername) 
    {
        # Add user name if set
        Add-Content -Path $RdpFilePath -Value "`r`nusername:s:$($VirtualComputerUsername)"
    }
    Write-Host "RDP file downloaded to: '$($RdpFilePath)'"
}

Login-AzureRmAccount -Credential (Get-Credential -Message "Provide username and password.") -SubscriptionName $AzureSubscription

SetNewDomainLable -ResourceGroupName $ResourceGroupName -PublicIpName $PublicIpName -NewDomainLable $NewDomainLable

GetRdpFile -ResourceGroupName $ResourceGroupName `
             -VirtualComputerName $VmName `
             -PublicIpName $PublicIpName  `
             -VirtualComputerUserName $Username
