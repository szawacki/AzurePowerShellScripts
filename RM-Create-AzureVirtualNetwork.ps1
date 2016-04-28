Function Create-AzureVirtualNetwork {
    <#

        .SYNOPSIS

        Create azure virtual network.



        .DESCRIPTION

        This function creates a new azure virtual network in an azure resource group. If the resource group does not exist, it will be created.


        .PARAMETER ResourceGroupName 

        Name of the resource group, to create the virtual network in.



        .PARAMETER ResourceGroupLocation 

        Location of the resource group.



        .PARAMETER VNetName

        Virtual network name.



        .PARAMETER VnetAddressPrefix 

        The virtual network adress prefix. Set as IP-Adress with notation.



        .PARAMETER SubnetName 

        Name of the virtual subnet. On esubnet is mandatory.



        .PARAMETER SubnetAddressPrefix

        The virtual subnet adress prefix. Set as IP-Adress with notation. Must be inside virtual network scope.



        .EXAMPLE 

        Create-AzureVirtualNetwork -ResourceGroupName "VnetResourceGroup" -ResourceGroupLocation "west europe" -VNetName "Vnet1" -VnetAddressPrefix "10.0.0.0/16" -SubnetName "SUB1" -SubnetAddressPrefix "10.0.0.0/24"

    
    #>

    Param(  [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]  
            [string]$ResourceGroupName,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]  
            [string]$ResourceGroupLocation,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]  
            [string]$VNetName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$VnetAddressPrefix,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]  
            [string]$SubnetName,

            [Parameter(Mandatory=$true)]
            [ValidateNotNullOrEmpty()]  
            [string]$SubnetAddressPrefix
    )

    # Check for existing resource group
    $ResourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation -ErrorAction SilentlyContinue

    if (!$ResourceGroup)
    {
        # Create new resource group
        $ResourceGroup = New-AzureRmResourceGroup -Name $ResourceGroupName -Location $ResourceGroupLocation
    }

    Write-Host "Get virtual network: $($VNetName)"
    $Vnet = Get-AzureRmVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroup.ResourceGroupName -ErrorAction SilentlyContinue

    if(!$Vnet) 
    {
        $SubnetConfig = New-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix -ErrorAction Stop

        Write-Host "Virtual network $($VNetName) not found, creating new..."
        $Vnet = New-AzureRmVirtualNetwork -Name $VNetName `
                                            -ResourceGroupName $ResourceGroup.ResourceGroupName `
                                            -Location $ResourceGroup.Location `
                                            -AddressPrefix $VnetAddressPrefix `
                                            -Subnet $SubnetConfig `
                                            -ErrorAction Stop
    } 
    else 
    {
        $SubnetConfig = Get-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -VirtualNetwork $Vnet -ErrorAction SilentlyContinue

        if (!$SubnetConfig)
        {
            Write-Host "Subnet $($SubnetName) not found, creating new..."
            $Vnet | Add-AzureRmVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetAddressPrefix -ErrorAction Stop
        }
    }
}
