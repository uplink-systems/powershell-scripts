<#
.SYNOPSIS
    Backup RDM data source sessions
.DESCRIPTION
    Backup all configured sessions from a Remote Desktop Manager datasource to an .rdm-file
.PARAMETER DataSourceName
    (Required) Name of RDM datasource to backup to file.
.PARAMETER BackupPwd
    (Required) Password to encrypt the backup file.
.PARAMETER BackupPath
    (Optional) Filename and path of the file to backup the sessions to.
.EXAMPLE
    Backup-RDMDatasourceSessions -DataSourceName "MyRdmDatasource" -BackupPwd "Sup3rS3cureP@ssw0rd" -BackupPath "C:\temp\RdmBkup.rdm"
#>

#Requires -Version 7.2  

Param(
    # mandatory parameter $DataSourceName
    [Parameter(Mandatory=$true)] [String] $DataSourceName,
    # mandatory parameter $BackupPwd
    [Parameter(Mandatory=$true)] [String] $BackupPwd,
    # optional parameter $BackupPath
    [Parameter(Mandatory=$false)] [String] $BackupPath = "$ENV:temp\RDM-Backup-$DataSourceName.rdm"
)

$ErrorActionPreference = 'SilentlyContinue'

# Check if RDM PS module is installed; install, if not...
If(-not (Get-Module Devolutions.PowerShell -ListAvailable)){
    Install-Module -Name "Devolutions.PowerShell" -Scope CurrentUser -Force
} Else {
    Update-Module -Name "Devolutions.Powershell" -Scope CurrentUser -Force
}

# Powershell module version info
$PsModuleVersion = (Get-InstalledModule -Name "Devolutions.Powershell").Version
Write-Host -Object "Using module version: $PsModuleVersion"

# Adapt password
$SecureBackupPwd = ConvertTo-SecureString -String "$BackupPwd" -AsPlainText -Force

# Backup/export sessions...
Write-Host -Object "Backing up sessions from datasource $DataSourceName to $BackupPath..."
Set-RDMCurrentDataSource -DataSource $(Get-RDMDataSource -Name $DataSourceName)
Export-RDMSession -Path $BackupPath -Sessions $(Get-RDMSession) -IncludeCredentials -IncludeAttachements -XML -Password $SecureBackupPwd