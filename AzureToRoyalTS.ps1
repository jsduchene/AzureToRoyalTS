#Auth to your azure account
Add-AzureRmAccount

#Import required modules
Import-Module RoyalDocument.PowerShell
Import-Module AzureRM.Compute
Import-Module AzureRM.Network

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
	$CredentialFolder = Get-RoyalObject -Name "Credentials" -Folder $RootFolder
	$AzCredential = New-RoyalObject -Folder $CredentialFolder -Name "AZCredentials" -Type RoyalCredential
	$AzCredential.UserName = "WINDOWSTOUCH\jsduchene"
	
	return $currentFolder
}

##############################################
# Global Variables 
# 
# To modify according you needs
##############################################
$fileName = "<PATH TO THE DOCUMENT>\AzureEnvironment.rtsz"
$azCredential = "<PUT YOUR USER ACCOUNT THERE>"
$docName = "Microsoft Azure Environment"

# Instantiate the document
$store = New-RoyalStore -UserName ((Get-Item Env:\USERNAME).Value)
$royalDocument = New-RoyalDocument -Store $store -Name $docName -FileName $fileName



# Browse Azure to create connection
foreach($activeSubscription in (Get-AzureRmSubscription | Sort SubscriptionName)) {
    
    $subscriptionName = $activeSubscription.Name
	Write-Host "#######   Next Subscription    #########################"
    Write-Host "Importing Subscription: $subscriptionName - $($activeSubscription.SubscriptionId)"

    Select-AzureRmSubscription -SubscriptionId $activeSubscription.SubscriptionId
	
	#Check Resource Provider of Subscription
	
	If((Get-AzureRmResourceProvider | Where-Object {$_.ProviderNamespace -Match "Microsoft.Compute"}) -ne $null)
	{
		# Loading VMs
		$vms = Get-AzureRmVM
		foreach ($vm in $vms)
		{
			$vmName = $vm.Name
			$nic = $vm.NetworkProfile.NetworkInterfaces[0].Id.Split('/') | select -Last 1
			if ( (Get-AzureRmNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nic).IpConfigurations.PublicIpAddress -eq $null )
			{
				continue
			}
			# Getting Public IP Address
			$publicIpName =  (Get-AzureRmNetworkInterface -ResourceGroupName $vm.ResourceGroupName -Name $nic).IpConfigurations.PublicIpAddress.Id.Split('/') | select -Last 1
			$publicIpAddress = (Get-AzureRmPublicIpAddress -ResourceGroupName $vm.ResourceGroupName -Name $publicIpName).IpAddress
			# Creating the connection
			if($publicIpAddress -ne "Not Assigned") {
				$uri = "$($publicIpAddress):3389";
				Write-Host "Importing Windows VM - $vmName - $uri"

				$lastFolder = CreateRoyalFolders -FolderStructure "Connections/$subscriptionName" -Splitter  "\/" -Folder $royalDocument -Credential $azCredential

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
		Write-Host "/!\ Subscription does not contain Computer Provider"
	}
}

#Saving and closing the document
Out-RoyalDocument -Document $royalDocument -FileName $fileName
Close-RoyalDocument -Document $royalDocument
