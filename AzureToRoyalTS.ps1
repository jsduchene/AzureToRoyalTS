##############################################################################
##############################################################################
##							Azure To Royal TS Script
##							Created by Jean-Sébastien DUCHÊNE
##							Website : microsofttouch.fr
##							Inspired from script Ryan Hoffman (tekmaven)
##							Version 0.1.0 (Updated for AzureRM Depreciation)
##
##	Basic script to build Royal TS Document from Azure Subscriptions for 
##  Windows VM Only I was bored to download RDP file each time.
##  It does not take lots of scenarios and does not handle all exceptions
##  Requirements : PowerShell 5.1
## 				   Import-Module RoyalDocument.PowerShell
## 				   Import-Module Az
##############################################################################
##############################################################################

#Auth to your azure account
Add-AzAccount

#Import required modules
Import-Module RoyalDocument.PowerShell


# Function CreateRoyalFolder to populate the document
function CreateRoyalFolders()
{
    param(
			[string]$folderStructure,
			[string]$splitter,
			[String]$credential,
			$Folder
	    )
	$currentFolder = $Folder
	$RootFolder = $Folder

	$folderStructure -split $splitter | %{
		$folder = $_
		$existingFolder = Get-RoyalObject -Folder $currentFolder -Name $folder -Type RoyalFolder
		if($existingFolder)
		{
			Write-Verbose "Folder $folder already exists - using it"
			$currentFolder = $existingFolder
		}
		else
		{
			Write-Verbose "Folder $folder does not exist - creating it"
			$newFolder= New-RoyalObject -Folder $currentFolder -Name $folder -Type RoyalFolder
			$currentFolder  = $newFolder
		}	
	}
	
	return $currentFolder
}

##############################################
# Global Variables 
# 
# To modify according you needs
##############################################
$fileName = "<PATHTOSTORERTSZ>\AzureEnv.rtsz"
$credential = "<AZURE CREDENTIAL>"
$docName = "Microsoft Azure Environment"
$rdpPort = 3389

# Instantiate the document
$store = New-RoyalStore -UserName ((Get-Item Env:\USERNAME).Value)
$royalDocument = New-RoyalDocument -Store $store -Name $docName -FileName $fileName



# Browse Azure to create connection
foreach($activeSubscription in (Get-AzSubscription | Sort SubscriptionName)) {
    
    $subscriptionName = $activeSubscription.Name
	Write-Host "#######   Next Subscription    #########################"
    Write-Host "Importing Subscription: $subscriptionName - $($activeSubscription.SubscriptionId)"

    Select-AzSubscription -Subscription $activeSubscription.SubscriptionId
	
	#Check Resource Provider of Subscription 
	
	If((Get-AzResourceProvider | Where-Object {$_.ProviderNamespace -Match "Microsoft.Compute"}) -ne $null)
	{
		
		# Loading VMs
		$vms = Get-AzVM
		if ($vms -ne $null)
		{
			If ($AzCredential -eq $null)
			{
				# Create Azure Credentials
				$CredentialFolder = Get-RoyalObject -Name "Credentials" -Folder $royalDocument
				$AzCredential = New-RoyalObject -Folder $CredentialFolder -Name "AZCredentials" -Type RoyalCredential
				$AzCredential.UserName = $credential
			}
			
			foreach ($vm in $vms)
			{
				$vmName = $vm.Name
				$nic = $vm.NetworkProfile.NetworkInterfaces[0].Id.Split('/') | select -Last 1
				if ( (Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nic).IpConfigurations.PublicIpAddress -eq $null )
				{
					continue
				}
				# Getting Public IP Address
				$publicIpName =  (Get-AzNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nic).IpConfigurations.PublicIpAddress.Id.Split('/') | select -Last 1
				$publicIpAddress = (Get-AzPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $publicIpName).IpAddress
				# Creating the connection
				if($publicIpAddress -ne "Not Assigned") {
					$uri = "$($publicIpAddress):$($rdpPort)";
					Write-Host "Importing Windows VM - $vmName - $uri"

					$lastFolder = CreateRoyalFolders -FolderStructure "Connections/$subscriptionName" -Splitter  "\/" -Folder $royalDocument

					$newConnection = New-RoyalObject -Folder $lastFolder -Type RoyalRDSConnection -Name $vmName
					$newConnection.URI = $uri
					$newConnection.CredentialMode = 4
					$newConnection.CredentialName = "AZCredentials"
				}
				else {
					Write-Host "Skipping $vmName, no public ip address"
				}
			}
		}
		else
		{
			Write-Host "No VMs on this subscription"
		}
	}
	else
	{
		Write-Host "/!\ Subscription does not contain Azure.Compute Provider"
	}
}

#Saving and closing the document
Out-RoyalDocument -Document $royalDocument -FileName $fileName
Close-RoyalDocument -Document $royalDocument
