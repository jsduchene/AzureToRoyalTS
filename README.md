# AzureToRoyalTS
Basic script to build Royal TS Document from Azure Subscriptions for Windows VM Only
I was bored to download RDP file each time.

First this script is inspired from a previous project held by Ryan Hoffman (tekmaven)
This is a refresh to take ARM and Royal TS new PowerShell Module.

###### Requirements #######
- PowerShell 5.1
- Import-Module RoyalDocument.PowerShell
- Import-Module AzureRM.Compute
- Import-Module AzureRM.Network
- Rights to the Subscription

###### What it does #######
- List all the subscription and browse for VM and their public IP Address
- Create a Royal TS Document
- Recreate the Azure Hierarchy
- Create RDP Connection for each VM which has a public IP Address
- Link the default Credential to the VM

###### DISCLAMER ##########
This script has been created for Lab Scenarios. There is no Warranty !!
There are several scenarios which are not taken into consideration :
- Azure Bastion
- Linux VMs with SSL
- VMs without public IP Address
- Different credentials for group of VMs
- RDP port customization. I've put the default port but you can change it in the script. I do not browse for NSG looking at the RDP port.
- Several Exceptions and scenarios 
- Etc

All those scenarios are improvment areas if someone has time on this project

Thanks
 
