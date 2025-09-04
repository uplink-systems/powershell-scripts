<#PSScriptInfo
  .VERSION 1.0.0.0
  .GUID 96d7be91-9a03-4fd6-be50-207cd78a1349
  .AUTHOR Andreas Schreiner
  .COMPANYNAME Andreas Schreiner IT-Services
  .COPYRIGHT (c) 2025 Andreas Schreiner IT-Services. All rights reserved.
  .TAGS Terraform Deploy Projects
  .PROJECTURI https://github.com/uplink-systems/powershell-scripts/Microsoft/M365/Intune/Compliance/
  .LICENSEURI https://github.com/uplink-systems/powershell-scripts/LICENSE
  .ICONURI
  .EXTERNALMODULEDEPENDENCIES
  .REQUIREDSCRIPTS
  .EXTERNALSCRIPTDEPENDENCIES
  .RELEASENOTES
  .PRIVATEDATA
    Created=04.09.2025
    Modified=04.09.2025
#>
<#
  .SYNOPSIS
    The script is the detection part of a custom Intune compliance check.
  .DESCRIPTION
    The script is the detection part of a custom Intune compliance check on Entra ID
    joined devices. It checks for unapproved members of the local administrators group.
    Approved members are in this case (must be modified to your needs):
    - the built-in local administrator account
    - a custom user named 'admin.local'
    - the primary device user (in case of Autopilot profiles with admin enrollment)
    - the tenant's role 'Global Administrator' (SID)
    - the tenant's role 'Azure AD Joined Device Locaal Administrator' (SID)
  .NOTES
    Version:         1.0.0.0
    Author:          Andreas Schreiner
    Copyright:       Andreas Schreiner IT Services
    Creation Date:   04.09.2025
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

$Result = @{
  "Admin count"                   = $Admins.Count
}
return $Result | ConvertTo-Json -Compress
