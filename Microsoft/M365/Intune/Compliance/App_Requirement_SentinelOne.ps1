<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID a1a992b2-a214-4aef-8189-453cda25c842
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
        Created=24.07.2024
        Modified=04.09.2025
#>

<#
    .SYNOPSIS
    The script is the detection part of a custom Intune compliance check.
    .DESCRIPTION
    The script is the detection part of a custom Intune compliance check. It checks
    if SentinelOne service is installed, running and auto-starting.
    .NOTES
        Version:         1.0.0.0
        Author:          Andreas Schreiner
        Copyright:       Andreas Schreiner IT Services
        Creation Date:   24.07.2024
    .OUTPUTS
    System.Management.Automation.PSCustomObject
    .COMPONENT
    Microsoft Intune
#>


# SentinelOne Agent service (installed/running/autostarting)
[bool]$SvcSentinelAgent = $false
if (Get-Service -Name "SentinelAgent") { [bool]$SvcSentinelAgent = $true }
[bool]$SvcSentinelAgentStatus = $false
if ((Get-Service -Name "SentinelAgent").Status -eq "4") { [bool]$SvcSentinelAgentStatus = $true }
[bool]$SvcSentinelAgentStartType = $false
if ((Get-Service -Name "SentinelAgent").StartType -eq "2") { [bool]$SvcSentinelAgentStartType = $true }

# Build result output and convert to json to validate with rules
$Result = @{
  "SentinelOne Agent is installed"              = $SvcSentinelAgent
  "SentinelOne Agent is running"                = $SvcSentinelAgentStatus
  "SentinelOne Agent is starting automatically" = $SvcSentinelAgentStartType
}
return $Result | ConvertTo-Json -Compress
