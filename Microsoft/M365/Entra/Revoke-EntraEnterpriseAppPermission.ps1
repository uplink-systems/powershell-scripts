<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID 1604942f-72bb-4c2c-9ed9-83374d96afe5
    .AUTHOR Andreas Schreiner
    .COMPANYNAME Andreas Schreiner IT-Services
    .COPYRIGHT (c) 2025 Andreas Schreiner IT-Services. All rights reserved.
    .TAGS Terraform Deploy Projects
    .PROJECTURI https://github.com/uplink-systems/powershell-scripts/HashiCorp/Terraform/
    .LICENSEURI https://github.com/uplink-systems/powershell-scripts/LICENSE
    .ICONURI
    .EXTERNALMODULEDEPENDENCIES
    .REQUIREDSCRIPTS
    .EXTERNALSCRIPTDEPENDENCIES
    .RELEASENOTES
    .PRIVATEDATA
        CreateDate=06.02.2025
        ModifyDate=04.09.2025
#>

<#
    .SYNOPSIS
        This script removes permission grants from Entra Enterprise Apps.
    .DESCRIPTION
        The script removes admin and/or user permission grants from Entra Enterprise Apps.
        The script forks and is based on Graph-AdAppPerm-Del.ps1 from CIAOPS:
        https://github.com/directorcia/Office365/blob/master/graph-adappperm-del.ps1
        The script is customized to the uplink.systems-Infrastructure needs, script syntax
        and naming convention.
    .NOTES
        Version:         1.0.0.0
        Author:          Andreas Schreiner
        Copyright:       Andreas Schreiner IT Services
        Creation Date:   04.08.2023
    .EXAMPLE
        .\<File-Name>.ps1
    .EXAMPLE
        PowerShell.exe -ExecutionPolicy Bypass -File .\<File-Name>.ps1
    .EXAMPLE
        PowerShell.exe -Command {Unblock-File .\<File-Name>.ps1}
        !! Unblock the Script if downloaded from Internet
    .INPUTS
        None.
    .OUTPUTS
        None.
    .LINK
        https://www.uplink.systems/
    .LINK
        https://www.it-services.de.com/
	.LINK
		https://github.com/uplink-systems/powershell-scripts/Microsoft/M365/Entra/
#>

function Revoke-EntraEnterpriseAppPermission {

    param(                        
        [Switch] $Debug = $false     ## If -debug parameter don't prompt for input
    )

    # clear console windows
    Clear-Host

    # set default $ErrorActionPreference; clear $Error variable
    $ErrorActionPreference = "Stop"
    $Error.Clear()

    # start logging to filein current directory if $Debug is $true
    if ($Debug) {Start-Transcript "..\$((Get-Item -Path $PSCommandPath).Basename).txt" | Out-Null}

    ## Variables
    $SystemMessageColor = "Cyan"
    $ProcessMessageColor = "Green"
    $ErrorMessageColor = "Red"
    $WarningMessageColor = "Yellow"

    # START PROCESSING...
    Write-Host -ForegroundColor $SystemMessageColor "Script started...`n"
    Write-Host -ForegroundColor $SystemMessageColor -BackgroundColor DarkBlue ">>>>>> UPLINK SYSTEMS <<<<<<`n"
    Write-Host "--- Remove permission grants from an Azure AD enterprise application in a tenant ---"

    ## check if AzureAD powershell module is available
    Write-Host -ForegroundColor $ProcessMessageColor "`nChecking for Azure AD PowgerShell module..."
    if (Get-Module -ListAvailable -Name AzureAD) {
        # connect to Azure AD if module is available
        Write-Host -ForegroundColor $ProcessMessageColor "Azure AD PowerShell Module found... Connecting to Azure AD..."
        Connect-AzureAD
    }
    else {
        # guide the operator to install module and exit script if module is unavailable
        Write-Host -ForegroundColor $WarningMessageColor -BackgroundColor $ErrorMessageColor "Azure AD PowerShell Module not found. Please install and re-run script`n"
        Write-Host "You can install the Azure AD Powershell module by:`n"
        Write-Host "    1. Launching an elevated Powershell console then,"
        Write-Host "    2. Running the command,'Install-Module AzureAD'.`n"
        if ($Debug) {Stop-Transcript | Out-Null}
        Pause                                                                               ## Pause to view error on screen
        exit 0                                                                              ## Terminate script 
    }
    $Results = Get-AzureADServicePrincipal -All $true | Sort-Object DisplayName | Out-GridView -PassThru -Title "Select Enterprise Application (Multiple selections permitted)"
    ForEach ($Result in $Results) {             # loop through all selected options
        Write-Host -ForegroundColor $ProcessMessageColor "Commencing",$Result.DisplayName
        # Get Service Principal using objectId
        $sp = Get-AzureADServicePrincipal -ObjectId $Results.ObjectId
        # Menu selection for User or Admin consent types
        $ConsentType = @()
        $ConsentType += [PSCustomObject]@{
            Name = "Admin consent";
            Type = "allprincipals"
        }
        $ConsentType += [PSCustomObject]@{
            Name = "User consent";
            Type = "principal"
        }
        $ConsentSelects = $ConsentType | Out-GridView -PassThru -Title "Select Consent type (Multiple selections permitted)"
        # loop through all selected options
        ForEach ($ConsentSelect in $ConsentSelects) {
            Write-Host -ForegroundColor $ProcessMessageColor "Commencing for",$ConsentSelect.Name
            # get all delegated permissions for the service principal
            $spOAuth2PermissionsGrants = Get-AzureADOAuth2PermissionGrant -All $true | Where-Object { $_.ClientId -eq $sp.ObjectId }
            $Info = $spOAuth2PermissionsGrants | Where-Object { $_.ConsentType -eq $ConsentSelect.Type }
            If ($Info) {            # if there are permissions set
                If ($ConsentSelect.Type -eq "principal") {  # user consent
                    $UserNames = @()
                    ForEach ($Item in $Info) {
                        $UserNames += Get-AzureADUser -ObjectId $Item.PrincipalId
                    }
                    $SelectUsers = $UserNames | Select-Object Displayname, UserPrincipalName, ObjectId | Sort-Object Displayname | Out-GridView -PassThru -Title "Select Consent type (Multiple selections permitted)"
                    ForEach ($SelectUser in $SelectUsers) {       # loop through all selected options
                        $InfoScopes = $Info | Where-Object { $_.PrincipalId -eq $SelectUser.ObjectId }
                        Write-Host -ForegroundColor $ProcessMessageColor "`n"$ConsentSelect.Name,"permissions for user",$SelectUser.DisplayName
                        ForEach ($InfoScope in $InfoScopes) {
                            Write-Host "`nResource ID =",$InfoScope.ResourceId
                            $Assignments = $InfoScope.scope -split " "
                            ForEach ($Assignment in $Assignments) {
                                Write-Host "-",$Assignment
                            }
                        }
                        Write-Host -ForegroundColor $ProcessMessageColor "`nSelect items to remove`n"
                        $Removes = $InfoScopes | Select-Object Scope, ResourceId, ObjectId | Out-GridView -PassThru -Title "Select permissions to delete (Multiple selections permitted)"
                        ForEach ($Remove in $Removes) {
                            Remove-AzureADOAuth2PermissionGrant -ObjectId $Remove.ObjectId
                            Write-Host -ForegroundColor $WarningMessageColor "Removed consent for",$Remove.Scope
                        }
                    }
                } 
                ElseIf ($ConsentSelect.Type -eq "allprincipals") {      # Admin consent
                    $InfoScopes = $Info | Where-Object {$null -eq $_.PrincipalId}
                    Write-Host -ForegroundColor $ProcessMessageColor $ConsentSelect.Name,"permissions"
                    ForEach ($InfoScope in $InfoScopes) {
                        Write-Host "`nResource ID =",$InfoScope.ResourceId
                        $Assignments = $InfoScope.Scope -split " "
                        ForEach ($Assignment in $Assignments) {
                            Write-Host "-",$Assignment
                        }
                    }
                    Write-Host -ForegroundColor $ProcessMessageColor "`nSelect items to remove`n"
                    $Removes = $InfoScopes | Select-Object Scope, ResourceId, ObjectId | Out-GridView -PassThru -Title "Select permissions to delete (Multiple selections permitted)"
                    ForEach ($Remove in $Removes) {
                        Remove-AzureADOAuth2PermissionGrant -ObjectId $Remove.ObjectId
                        Write-Host -ForegroundColor $WarningMessageColor "Removed consent for",$Remove.Scope
                    }
                }
            } Else {
                Write-Host -ForegroundColor $WarningMessageColor "`nNo",$ConsentSelect.Name,"permissions found for" ,$Results.DisplayName,"`n"
            }
        }
    }

    Write-Host -ForegroundColor $SystemMessageColor "`nScript finished..."
    if ($Debug) {Stop-Transcript | Out-Null}
}

Revoke-EntraEnterpriseAppPermission