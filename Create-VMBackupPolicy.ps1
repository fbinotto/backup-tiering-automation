<#
.SYNOPSIS
    Creates Azure Backup policies
.DESCRIPTION
    This script will create three enhanced and one standard Azure Backup policies
.NOTES

.LINK
    https://github.com/fbinotto/backup-tiering-automation/blob/main/Create-VMBackupPolicy.ps1
.EXAMPLE
    PS>.\Create-VMBackupPolicy.ps1
#>

# Create schedule and retention policy objects
$schPolEnhanced = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM -PolicySubType Enhanced
$schPolDefault = Get-AzRecoveryServicesBackupSchedulePolicyObject -WorkloadType AzureVM
$retPol = Get-AzRecoveryServicesBackupRetentionPolicyObject -WorkloadType "AzureVM"

$schPolEnhanced.ScheduleRunFrequency = 'Hourly'

# Create date in UTC format
$Dt = Get-Date
$Dt1 = (Get-Date -Year $Dt.Year -Month $Dt.Month -Day $Dt.Day -Hour $Dt.Hour -Minute 0 -Second 0 -Millisecond 0).ToUniversalTime()

# TIER-1 Schedule
$T1HourlySchedule = New-Object Microsoft.Azure.Commands.RecoveryServices.Backup.Cmdlets.Models.HourlySchedule
$T1HourlySchedule.Interval = 4
$T1HourlySchedule.WindowStartTime = $dt1
$T1HourlySchedule.WindowDuration = 24

# TIER-2 Schedule
$T2HourlySchedule = New-Object Microsoft.Azure.Commands.RecoveryServices.Backup.Cmdlets.Models.HourlySchedule
$T2HourlySchedule.Interval = 6
$T2HourlySchedule.WindowStartTime = $dt1
$T2HourlySchedule.WindowDuration = 24

# TIER-3 Schedule
$T3HourlySchedule = New-Object Microsoft.Azure.Commands.RecoveryServices.Backup.Cmdlets.Models.HourlySchedule
$T3HourlySchedule.Interval = 12
$T3HourlySchedule.WindowStartTime = $dt1
$T3HourlySchedule.WindowDuration = 24

$retPol.IsWeeklyScheduleEnabled = $false
$retPol.IsMonthlyScheduleEnabled = $false
$retPol.IsYearlyScheduleEnabled = $false

$subscriptions = Get-AzSubscription | ? State -eq 'Enabled'

foreach ($sub in $subscriptions) {

    Select-AzSubscription -SubscriptionObject $sub

    foreach ($vault in (Get-AzRecoveryServicesVault)) {

	  $retPol.DailySchedule.DurationCountInDays = 90
        $schPolEnhanced.HourlySchedule = $T1HourlySchedule
        $ProtectionPolicy = New-AzRecoveryServicesBackupProtectionPolicy -Name TIER-1 `
            -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPolEnhanced -VaultId $vault.Id

	  $retPol.DailySchedule.DurationCountInDays = 60
        $schPolEnhanced.HourlySchedule = $T1HourlySchedule
        $ProtectionPolicy = New-AzRecoveryServicesBackupProtectionPolicy -Name TIER-2 `
            -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPolEnhanced -VaultId $vault.Id

	  $retPol.DailySchedule.DurationCountInDays = 30
        $schPolEnhanced.HourlySchedule = $T3HourlySchedule
        $ProtectionPolicy = New-AzRecoveryServicesBackupProtectionPolicy -Name TIER-3 `
            -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPolEnhanced -VaultId $vault.Id

	  $retPol.DailySchedule.DurationCountInDays = 15
        $schPolDefault.ScheduleRunTimes.Clear()
        $schPolDefault.ScheduleRunTimes.Add($dt1)
        $ProtectionPolicy = New-AzRecoveryServicesBackupProtectionPolicy -Name TIER-4 `
            -WorkloadType AzureVM -RetentionPolicy $retPol -SchedulePolicy $schPolDefault -VaultId $vault.Id

    }
}

