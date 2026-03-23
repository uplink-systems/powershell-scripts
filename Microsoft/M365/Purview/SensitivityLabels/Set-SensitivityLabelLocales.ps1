<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 79de890b-6e1b-4000-b9f8-3065baf73a06
    .AUTHOR Andreas Schreiner
    .COMPANYNAME Andreas Schreiner IT-Services
    .COPYRIGHT (c) 2026 Andreas Schreiner IT-Services. All rights reserved.
    .TAGS Purview Security Compliance
    .PROJECTURI https://github.com/uplink-systems/powershell-scripts/Microsoft/M365/Purview/SensitivityLabels
    .LICENSEURI https://github.com/uplink-systems/powershell-scripts/LICENSE
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES
    .PRIVATEDATA
        Created=06.01.2026
        Modified=08.01.2026
#>

<#
    .SYNOPSIS
        The script configures multilanguage Display Names and Tooltips of sensitivity labels.
    .DESCRIPTION
        The script configures multilanguage Display Names and Tooltips of sensitivity labels.
        For details see repository folder's README.md
    .NOTES
        Version:         1.0.0.0
        Author:          Andreas Schreiner
        Copyright:       Andreas Schreiner IT Services
        Creation Date:   06.01.2026
    .PARAMETER Labels
        The array $Labels specifies the label name, the locales and the locale's content.
        See the .EXAMPLE section for how to specify and use it or the Repo folder's README.md.
    .OUTPUTS
        $Error.Count
    .COMPONENT
       Microsoft Security & Compliance
    .EXAMPLE
        $Labels = @(
          @("P_01", @("en-us","de-de"), @("Public","Öffentlich"), @("Public documents","Öffentliche Dokumente")),
          @("I_01", @("en-us","de-de"), @("Internal","Intern"), @("Internal documents","Interne Dokumente"))
        )
        .\Set-SensitivityLabelLocales.ps1 -Labels $Labels
#>

#Requires -Version 7.0

param(
  [Parameter(Mandatory=$true)] [Array] $Labels
)

$ErrorActionPreference = 'SilentlyContinue'
$Error.Clear()

if (Get-Module -ListAvailable -Name ExchangeOnlineManagement) {
  Import-Module -Name ExchangeOnlineManagement -Force
} 
else {
  Write-Host -Object "`nRequired 'ExchangeOnlineManagement' PowerShell module is not available... Exit..." -ForegroundColor Yellow
  exit 1
}

Connect-IPPSSession

Write-Host -Object "`nFound $($Labels.Count) sensitivity labels to configure:" -ForegroundColor DarkGray
Start-Sleep -Seconds 1

foreach ($Label in $Labels) {
  $LabelName    = $Label[0]
  $Languages    = $Label[1]
  $DisplayNames = $Label[2]
  $Tooltips     = $Label[3]
  $DisplayNameLocaleSettings = [PSCustomObject]@{LocaleKey='DisplayName';
  Settings=@(
    for ( $Index = 0; $Index -lt $Languages.Count; $Index = $Index + 1)
      {
        @{key=$Languages[$Index];Value=$DisplayNames[$Index];}
      }
    )
  }
  $TooltipLocaleSettings = [PSCustomObject]@{LocaleKey='Tooltip';
  Settings=@(
    for ( $Index = 0; $Index -lt $Languages.Count; $Index = $Index + 1)
      {
        @{key=$Languages[$Index];Value=$Tooltips[$Index];}
      }
    )
  }
  
  Write-Host -Object "  $LabelName " -ForegroundColor White -NoNewline
  Write-Host -Object "-> " -ForegroundColor DarkGray -NoNewline
  try {
    Set-Label -Identity $LabelName -LocaleSettings (ConvertTo-Json $DisplayNameLocaleSettings -Depth 2 -Compress),(ConvertTo-Json $TooltipLocaleSettings -Depth 2 -Compress) -ErrorAction Stop
    Write-Host -Object "Succeeded..." -ForegroundColor Green
  }
  catch {
    Write-Host -Object "Failed..." -ForegroundColor Red
  }
  finally {
    Start-Sleep -Seconds 1
  }
}

Disconnect-IPPSSession

exit $Error.Count