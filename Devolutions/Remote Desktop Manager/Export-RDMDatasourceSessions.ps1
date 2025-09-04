#Requires -Version 7.2  

Param(
    # mandatory parameter $DataSourceName
    [Parameter(Mandatory=$true)] [String] $DataSourceName,
    # mandatory parameter $ExportPwd
    [Parameter(Mandatory=$true)] [String] $ExportPwd,
    # optional parameter $ExportPath
    [Parameter(Mandatory=$false)] [String] $ExportPath = "$ENV:temp\RDM-Export-$DataSourceName.rdm"
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
$SecureExportPwd = ConvertTo-SecureString -String "$ExportPwd" -AsPlainText -Force

# Export sessions...
Write-Host -Object "Exporting sessions from datasource $DataSourceName to $ExportPath..."
Set-RDMCurrentDataSource -DataSource $(Get-RDMDataSource -Name $DataSourceName)
Export-RDMSession -Path $ExportPath -Sessions $(Get-RDMSession) -IncludeCredentials -IncludeAttachements -XML -Password $SecureExportPwd