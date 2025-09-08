<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID aae64c2b-c7b3-4ed6-aa79-5eb57d0a9a89
    .AUTHOR Andreas Schreiner
    .COMPANYNAME Andreas Schreiner IT-Services
    .COPYRIGHT (c) 2025 Andreas Schreiner IT-Services. All rights reserved.
    .TAGS Intune Compliance
    .PROJECTURI https://github.com/uplink-systems/powershell-scripts/Microsoft/M365/Intune/Compliance/
    .LICENSEURI https://github.com/uplink-systems/powershell-scripts/LICENSE
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES
    .PRIVATEDATA
        Created=08.09.2025
        Modified=08.09.2025
#>

<#
    .SYNOPSIS
    The script is the detection part of Intune custom compliance checks.
    .DESCRIPTION
    The script is the detection part of Intune custom compliance checks. It performs
    the following checks:
    - check if non-default accounts are member of local administrators group
    - check if hostname matches naming convention
    - check if organisation's CA certificate is present
    - check if Credential Guard is enabled
    - check if LAPS policy processing is successfull
    - check for free disk space
    For details see repository folder's README.md
    .NOTES
        Version:         1.0.0.0
        Author:          Andreas Schreiner
        Copyright:       Andreas Schreiner IT Services
        Creation Date:   08.09.2025
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    .COMPONENT
    Microsoft Intune
#>


##### Check if local administrators group contains unauthorized members (users or groups) #####
# Get builtin admin group name and admin name (in case of localized systems or if renamed)
$BuiltInAdminGroup = (Get-CimInstance -ClassName Win32_Group -Filter "SID = 'S-1-5-32-544' and Domain = '$env:COMPUTERNAME'").Name
$BuiltInAdminAccount = (Get-CimInstance -ClassName Win32_UserAccount -Filter "LocalAccount = TRUE and SID like 'S-1-5-%-500'").Name
# Retrieve all members of local Administrator group via ADSI
$Admins = {([ADSI]"WinNT://./$BuiltInAdminGroup").psbase.Invoke('Members') | ForEach-Object {([ADSI]$_).InvokeGet('AdsPath')}}.Invoke()
# Remove authorised users/groups/SIDs from the list of admins
$DefaultAdmins = `
"WinNT://$($env:COMPUTERNAME)/$BuiltInAdminAccount", `              # Local: built-in administrator account
"WinNT://$($env:COMPUTERNAME)/admin.local", `                       # Local: custom administrator account
"WinNT://AzureAD/$($env:USERNAME)", `                               # Entra ID: primary assigned user
"WinNT://S-1-12-1-<to-be-customized>", `                            # Entra ID: Global Administrator role SID
"WinNT://S-1-12-1-<to-be-customized>"                               # Entra ID: Azure AD Joined Device Local Administrator role SID
foreach ($DefaultAdmin in $DefaultAdmins) {
  $Admins.Remove($DefaultAdmin)
}

##### Check if device's computername follows the organization's naming convention or explicit names #####
[bool]$ComputerId = $false
# Define list of naming convention based computernames and explicit computernames
$ComputerNamesConvention  = "WIN-"
$ComputerNamesExplicit    = "KIRK", "SPOCK", "MCCOY"
# Check if device's computername is in the lists of permitted computernames
if (($env:COMPUTERNAME -match ($ComputerNamesConvention -join '|')) -or ($env:COMPUTERNAME -match ($ComputerNamesExplicit -join '|'))) {
  [bool]$ComputerId = $true
}

##### Check if organisations CA root certificate is present #####
[bool]$Certificate = $false
$ThumbprintCertCaRoot = "<CA_CERTIFICATE_THUMBPRINT>"
if (Get-ChildItem Cert:\LocalMachine\Root | Where-Object {$_.Thumbprint -eq $ThumbprintCertCaRoot}) {
  [bool]$Certificate = $true
}

##### Check if Credential Guard is enabled #####
[bool]$CredGuard = $false
$DeviceGuard = Get-CimInstance -ClassName "Win32_DeviceGuard" -Namespace "root\Microsoft\Windows\DeviceGuard"
if ($($DeviceGuard.SecurityServicesRunning -contains 1) -eq $true) {
  [bool]$CredGuard = $true
}

##### Check if Windows LAPS policy processing is running successfully to verify that LAPS is enabled
[bool]$LAPS = $false
$Events = Get-WinEvent -FilterHashtable @{ LogName='Microsoft-Windows-LAPS/Operational'; StartTime=$((Get-Date).AddDays(-2)); Id='10004' } -ErrorAction SilentlyContinue
if ($Events.Count -gt 0) {
  [bool]$LAPS = $true
}

##### Check for disk space on the system drive C:\ in GB
$DiskSpace = [math]::Round((Get-PSDrive -Name C).Free / 1024 / 1024 / 1024)



##### Build result output and convert to json to validate with rules ###
$Result = @{
  "Admin count"                   = $Admins.Count
  "Certificate is present"        = $Certificate
  "Computername is valid"         = $ComputerId
  "Credential Guard is enabled"   = $CredGuard
  "Free disk space"               = $DiskSpace
  "LAPS is enabled"               = $LAPS
}
return $Result | ConvertTo-Json -Compress
