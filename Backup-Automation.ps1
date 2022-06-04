<#
.SYNOPSIS
    Enable Azure Backup on VMs based on tag
.DESCRIPTION
    This script helps assigning the correct Azure Backup policy to a VM based on a tag 
.NOTES
    Requires the Az.ResourceGraph module to be installed
.LINK
    https://github.com/fbinotto/backup-tiering-automation/blob/main/Backup-Automation.ps1
.EXAMPLE
    PS>.\Backup-Automation.ps1

    No parameters are used as the script is supposed to be used in as an Azure Automation Runbook.
#>

# Ensures you do not inherit an AzContext in your runbook
Disable-AzContextAutosave -Scope Process

$accountId = ''
$vaultRGName = ''
$vaultName = ''

# Connect to Azure with user-assigned managed identity
Connect-AzAccount -Identity -AccountId $accountId

# Gets the list of all subscriptions
$subscriptions = Get-AzSubscription | foreach { $_.SubscriptionId }

# Query to get all backed up VMs
$query = "RecoveryServicesResources | where type in~ ('microsoft.recoveryservices/vaults/backupfabrics/protectioncontainers/protecteditems')"

# Execute query
$backups = Search-AzGraph -Subscription $subscriptions -Query $query

# Query to get all VMs
$query = "resources | where type in~ ('microsoft.compute/virtualmachines') | where tags.BackupTier != ''"

# Execute Query
$vms = Search-AzGraph -Subscription $subscriptions -Query $query

# Iterate through each VM
foreach ($vm in $vms) {
    Write-Output "-----------------------------------------------"
    Write-Output "Checking backup configuration for VM $($vm.name)"
    # Get tag value
    $tier = $vm.tags.BackupTier
    Write-Output "VM is assigned tag $tier"
    # if VM is backed up
    if ($backups.name -match $vm.Name -and $backups.Name -match $vm.ResourceGroup) {
        Write-Output "VM already exists in the vault"
        # Get current backup policy
        $policyName = ($backups | ? { $_.Name -match $vm.Name -and $_.Name -match $vm.ResourceGroup }).properties.policyid.split("/")[-1]
        $protectionState = ($backups | ? { $_.Name -match $vm.Name -and $_.Name -match $vm.ResourceGroup }).properties.currentProtectionState
        # Check if existing backup is in soft deleted state
        if ($protectionState -eq "SoftDeleted") {
            Write-Output "Backup for VM $($vm.name) iss in a soft-deleted state and manual intervention is required."
            continue
        }
        # Check if VM uses shared disk
        foreach ($disk in $vm.StorageProfile.DataDisks) {
            if ((Get-AzDisk -ResourceGroupName $vm.ResourceGroupName -DiskName $disk.Name).MaxShares) {
                Write-Output "$($vm.name) uses shared disk and backup is not supported."
                continue
            }
        }
        $vaultId = ($backups | ? { $_.Name -match $vm.Name -and $_.Name -match $vm.ResourceGroup }).properties.policyid.split("/")[0..8] -join "/"
        if ($policyName) {
            Write-Output "Using policy $policyName"
        }
        else {
            Write-Output "No policy assigned"
        }
        Write-Output "Using vault $vaultId"
        # depending on tag value
        switch ($tier) {
            # if TIER-1
            'TIER-1' {			
                Write-Output "Evaluating TIER-1..."			
                # and policy is not TIER-1
                if ($policyName -ne "TIER-1") {
                    Select-AzSubscription -SubscriptionId $vm.SubscriptionId | out-null
                    $xPolicy = "TIER-1"						
                    if ($protectionState -eq "ProtectionStopped") {
                        $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                        Microsoft.RecoveryServices/vaults/$vaultName/"
                    }						
                    # Get backup policy
                    try {
                        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                        $protectedItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -BackupManagementType AzureVM -Name $vm.Name -VaultId $vaultId
                        # Enable backup
                        if (Enable-AzRecoveryServicesBackupProtection -Item $protectedItem -policy $policy -VaultId $vaultId) {
                            Write-Output "Policy $xPolicy assigned to $($vm.Name)"
                        }
                    }
                    catch {
                        Write-Output "Failed to change backup policy for VM $($vm.name)"
                        Write-Output $Error[0]
                    }
                }
                else {
                    Write-Output "VM $($VM.name) already has the required backup policy assigned"
                }
            }
            # if TIER-2
            'TIER-2' {			
                Write-Output "Evaluating TIER-2 tier..."			
                # and policy is not TIER-2
                if ($policyName -ne "TIER-2") {
                    Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                    $xPolicy = "TIER-2"						
                    if ($protectionState -eq "ProtectionStopped") {
                        $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                        Microsoft.RecoveryServices/vaults/$vaultName/"
                    }						
                    # Get backup policy
                    try {
                        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                        $protectedItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -BackupManagementType AzureVM -Name $vm.Name -VaultId $vaultId
                        # Enable backup
                        if (Enable-AzRecoveryServicesBackupProtection -Item $protectedItem -policy $policy -VaultId $vaultId) {
                            Write-Output "Policy $xPolicy assigned to $($vm.Name)"
                        }
                    }
                    catch {
                        Write-Output "Failed to change backup policy for VM $($vm.name)"
                        Write-Output $Error[0]
                    }
                }
                else {
                    Write-Output "VM $($VM.name) already has the required backup policy assigned"
                }
            }
            # if TIER-3
            'TIER-3' {			
                Write-Output "Evaluating TIER-3 tier..."			
                # and policy is not TIER-3
                if ($policyName -ne "TIER-3") {
                    Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                    $xPolicy = "TIER-3"						
                    if ($protectionState -eq "ProtectionStopped") {
                        $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                        Microsoft.RecoveryServices/vaults/$vaultName/"
                    }						
                    # Get backup policy
                    try {
                        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                        $protectedItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -BackupManagementType AzureVM -Name $vm.Name -VaultId $vaultId
                        # Enable backup
                        if (Enable-AzRecoveryServicesBackupProtection -Item $protectedItem -policy $policy -VaultId $vaultId) {
                            Write-Output "Policy $xPolicy assigned to $($vm.Name)"
                        }
                    }
                    catch {
                        Write-Output "Failed to change backup policy for VM $($vm.name)"
                        Write-Output $Error[0]
                    }
                }
                else {
                    Write-Output "VM $($VM.name) already has the required backup policy assigned"
                }
            }
            # if TIER-4
            'TIER-4' {			
                Write-Output "Evaluating TIER-4 tier..."			
                # and policy is not TIER-4
                if ($policyName -ne "TIER-4") {
                    Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                    $xPolicy = "TIER-4"						
                    if ($protectionState -eq "ProtectionStopped") {
                        $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                        Microsoft.RecoveryServices/vaults/$vaultName/"
                    }						
                    # Get backup policy
                    try {
                        $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                        $protectedItem = Get-AzRecoveryServicesBackupItem -WorkloadType AzureVM -BackupManagementType AzureVM -Name $vm.Name -VaultId $vaultId
                        # Enable backup
                        if (Enable-AzRecoveryServicesBackupProtection -Item $protectedItem -policy $policy -VaultId $vaultId) {
                            Write-Output "Policy $xPolicy assigned to $($vm.Name)"
                        }
                    }
                    catch {
                        Write-Output "Failed to change backup policy for VM $($vm.name)"
                        Write-Output $Error[0]
                    }
                }
                else {
                    Write-Output "VM $($VM.name) already has the required backup policy assigned"
                }
            }
            Default {}
        }
    }
    else {
        Write-Output "VM doesn't have any backup"
        switch ($tier) {
            'TIER-1' {
                Write-Output "Evaluation TIER-1 tier..."
                Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                $xPolicy = "TIER-1"
                $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/Microsoft.RecoveryServices/vaults/$vaultName/"
				   
                if ($protectionState -eq "ProtectionStopped") {
                    $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                    Microsoft.RecoveryServices/vaults/$vaultName/"
                }						
                # Get backup policy
                try {
                    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                    # Enable backup
                    if (Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $vm.ResourceGroup -Name $vm.Name -Policy $policy -VaultId $vaultId) {
                        Write-Output "Backup enabled and policy $xPolicy assigned to $($vm.Name)"
                    }
                }
                catch {
                    Write-Output "Failed to change backup policy for VM $($vm.name)"
                    Write-Output $Error[0]
                }
            }
            'TIER-2' {
                Write-Output "Evaluation TIER-2 tier..."
                Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                $xPolicy = "TIER-2"
                $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                Microsoft.RecoveryServices/vaults/$vaultName/"
				   
                if ($protectionState -eq "ProtectionStopped") {
                    $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                    Microsoft.RecoveryServices/vaults/$vaultName/"
                }						
                # Get backup policy
                try {
                    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                    # Enable backup
                    if (Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $vm.ResourceGroup -Name $vm.Name -policy $policy -VaultId $vaultId) {
                        Write-Output "Backup enabled and policy $xPolicy assigned to $($vm.Name)"
                    }
                }
                catch {
                    Write-Output "Failed to change backup policy for VM $($vm.name)"
                    Write-Output $Error[0]
                }
            }
            'TIER-3' {
                Write-Output "Evaluation TIER-3 tier..."
                Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                $xPolicy = "TIER-3"
                $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                Microsoft.RecoveryServices/vaults/$vaultName/"
				   
                if ($protectionState -eq "ProtectionStopped") {
                    $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                    Microsoft.RecoveryServices/vaults/$vaultName/"
                }						
                # Get backup policy
                try {
                    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                    # Enable backup
                    if (Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $vm.ResourceGroup -Name $vm.Name -policy $policy -VaultId $vaultId) {
                        Write-Output "Backup enabled and policy $xPolicy assigned to $($vm.Name)"
                    }
                }
                catch {
                    Write-Output "Failed to change backup policy for VM $($vm.name)"
                    Write-Output $Error[0]
                }
            }
            'TIER-4' {
                Write-Output "Evaluation TIER-4 tier..."
                Select-AzSubscription -SubscriptionId $vm.SubscriptionId
                $xPolicy = "TIER-4"
                $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                Microsoft.RecoveryServices/vaults/$vaultName/"
				   
                if ($protectionState -eq "ProtectionStopped") {
                    $vaultId = "/subscriptions/$($vm.SubscriptionId)/resourceGroups/$vaultRGName/providers/
                    Microsoft.RecoveryServices/vaults/$vaultName/"
                }						
                # Get backup policy
                try {
                    $policy = Get-AzRecoveryServicesBackupProtectionPolicy -Name $xPolicy -VaultId $vaultId
                    # Enable backup
                    if (Enable-AzRecoveryServicesBackupProtection -ResourceGroupName $vm.ResourceGroup -Name $vm.Name -policy $policy -VaultId $vaultId) {
                        Write-Output "Backup enabled and policy $xPolicy assigned to $($vm.Name)"
                    }
                }
                catch {
                    Write-Output "Failed to change backup policy for VM $($vm.name)"
                    Write-Output $Error[0]
                }
            }
            Default {}
        }
    }  
}
