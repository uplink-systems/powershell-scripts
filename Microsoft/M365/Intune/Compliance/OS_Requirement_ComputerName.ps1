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
    joined devices. It checks it the computername matches either a naming convention
    or matches a list of other valid names.
    Approved computernames are in this case (must be modified to your needs):
    - computername following the convention to start with "WIN-"
    - computername is one of "KIRK", "SPOCK" or "MCCOY"
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

##### Check if device's computername follows the organization's naming convention or explicit names #####
[bool]$ComputerName = $false
# Define list of naming convention based computernames and explicit computernames
$ComputerNamesConvention  = "WIN-"
$ComputerNamesExplicit    = "KIRK", "SPOCK", "MCCOY"
# Check if device's computername is in the lists of permitted computernames
if (($env:COMPUTERNAME -match ($ComputerNamesConvention -join '|')) -or ($env:COMPUTERNAME -match ($ComputerNamesExplicit -join '|'))) {
  [bool]$ComputerName = $true
}

##### Build result output and convert to json to validate with rules ###
$Result = @{
  "Computername is valid"         = $ComputerName
}
return $Result | ConvertTo-Json -Compress
