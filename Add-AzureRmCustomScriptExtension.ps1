Function Add-AzureRmCustomScriptExtension()
{
    <#

    .SYNOPSIS

    Adds a custom script extension to a virtual machine.



    .DESCRIPTION


    Custom script extensions allow deploying software packages to azure virtual machines. This script adds a custom script extension to a virtual machine that is already created, or during
    creation.


    .PARAMETER VmName

    Name of the virtual machine.


    .PARAMETER ResourceGroupName
    
    Name of the virtual machine's resource group. 


    .PARAMETER AdminName 

    Name of the local administrator account.


    .PARAMETER AdminPwd

    Password of the local administrator account.




    .EXAMPLE 

    Add a custom script extension to virtual machine named TestVM1.

    Add-AzureRmCustomScriptExtension -VmName "TestVM1" `
                                     -ResourceGroupName "TestVm1ResourceGroup" `
                                     -AdminName "Admin" `
                                     -AdminPwd "123456" `



    .NOTES

    This function needs some configuration.

    Your custom scritp extension needs at least one powershell script to be run during installation. Additional files can be included.
    Place all your files inside an azure storage blob.
    List all your files (file names only, not full qualified path) in the array passed to parameter "-FileName" in line 97.
    Set resource group name, storage account name and container name, of your storage blob to the corresponding variables in lines 85 - 87.
    Pass the script to be run to "-Run" parameter in line 98. The script must be part of the array. 


    .LINK
    
    https://azure.microsoft.com/de-de/blog/automating-vm-customization-tasks-using-custom-script-extension/

    #>

    Param(  [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$VmName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$ResourceGroupName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$AdminName,

            [Parameter(Mandatory=$true)] 
            [ValidateNotNullOrEmpty()] 
            [string]$AdminPwd
    )

    $custoimScriptExtensionResourceGroupName = ""
    $custoimScriptExtensionStorageAccount = ""
    $custoimScriptExtensionConatiner = ""
   
    $key = (Get-AzureRmStorageAccountKey -ResourceGroupName $custoimScriptExtensionResourceGroupName -Name $custoimScriptExtensionStorageAccount -ErrorAction Stop).Key1

    Set-AzureRmVMCustomScriptExtension -ResourceGroupName $ResourceGroupName `
                                       -VMName $VmName `
                                       -Name "CustomInstallation" `
                                       -StorageAccountName $custoimScriptExtensionStorageAccount `
                                       -ContainerName $custoimScriptExtensionConatiner `
                                       -StorageAccountKey $key `
                                       -FileName @('<Add file to this array>') `
                                       -Run 'script to run' `
                                       -Argument "$($AdminName) $($AdminPwd)" `
                                       -Location "west europe" `
                                       -ErrorAction Stop  
}
