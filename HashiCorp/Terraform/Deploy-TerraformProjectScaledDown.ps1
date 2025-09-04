<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID e3365ce3-312e-4f3f-a85f-b58959f02790
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
        CreateDate=14.03.2025
        ModifyDate=04.09.2025
#>

<#
    .SYNOPSIS
        This script is intended to make it easier to automatically process Terraform project deployment
		tasks managing multiple projects.
    .DESCRIPTION
		This script is intended to make it easier to process Terraform project deployment tasks managing
		multiple projects. It makes use of the UplinkSystems.Terraform module that is available in the
		PowerShell Gallery.
        The script must be located in the root of a directory that contains one ore more Terraform project
		root folders. First, it reads the root folders and creates a menu to choose which project to manage.
		After selecting the project it offers Terraform tasks (init/plan/apply/destroy/etc.) to process.
		The script It is for my internal use only but can be customized to your needs. Therefore itcontains
		a selection of task preconfigured as default but it can be customized to everyones own needs.
		Compared to the full version of the script it has a downscaled feature set and no console output 
		besides menus and app outputs. 
    .NOTES
        Version:        1.0.0.0
        Author:         Andreas Schreiner
        Copyright:      Andreas Schreiner IT Services
        Creation Date:  14.03.2025
    .EXAMPLE
        .\<File-Name>.ps1
    .EXAMPLE
        PowerShell.exe -ExecutionPolicy Bypass -File .\<File-Name>.ps1
    .INPUTS
        None.
    .OUTPUTS
        None.
    .LINK
        https://www.uplink.systems/
    .LINK
        https://www.it-services.de.com/
	.LINK
		https://github.com/uplink-systems/powershell-scripts/HashiCorp/Terraform/
	.LINK
		https://github.com/uplink-systems/powershell-modules/UplinkSystems.Terraform/
#>

#Requires -Version 7.0

begin {
	$TerraformPsModule = 'UplinkSystems.Terraform'
	function Enter-TerraformDeployment {
		Write-Host -Object "`n`nEnter Terraform project deployment...`n" -ForegroundColor DarkGray
		Start-Sleep -Seconds 1
		Write-Host -Object "`nImporting UplinkSystems.Terraform module for PowerShell... " -ForegroundColor DarkGray -NoNewline
		Try {
			Import-Module -Name $TerraformPsModule -Force -ErrorAction Stop
		}
		Catch {
			Write-Host -Object "Failed...`n" -ForegroundColor Red -NoNewline
			Start-Sleep -Seconds 1
			Exit-TerraformDeployment
		}
	}
	function Show-ProjectsMenu {
		$ProjectsDirectories = Get-ChildItem -Path $PSScriptRoot -Directory | Select-Object Name
		$ProjectsMenu = @{}
		Write-Host -Object "`n============= Select Terraform Project Option ================="
		Write-Host
		for ($i=1; $i -le $ProjectsDirectories.count; $i++) {
			Write-Host -Object "$i > $($ProjectsDirectories[$i-1].name)" 
			$ProjectsMenu.Add($i,($ProjectsDirectories[$i-1].name))
		}
		Write-Host -Object "`n==============================================================="
		[int]$ans = Read-Host 'Select Option'
		$Global:ProjectDirectory = $ProjectsMenu.Item($ans)
		if ($null -eq $ProjectDirectory) {
			Write-Host -Object "`nInvalid selection..." -ForegroundColor DarkGray
			Exit-TerraformDeployment
		}
	}
	function Show-TerraformMenu {
		$TerraformTasks = @(
			"terraform init"
			"terraform get -update"
			"terraform plan -lock=false"
			"terraform apply -auto-approve"
			"terraform <custom task>"
			"EXIT"
		)
		do {
			$i = 1
			Write-Host "`n============= Select Terraform Command Option ================="
			Write-Host
			$TerraformTasks | ForEach-Object { Write-Host -Object "$i > $_" ; if ($i -lt $TerraformTasks.Count){$i ++} }
			Write-Host "`n==============================================================="
			$Global:TerraformTask = Read-Host "Select Option"
		} until (($null -ne $TerraformTask -as [int]) -and ($TerraformTask -ge 1 -le $i))
		switch ($TerraformTask) {
				1  { Invoke-TerraformInit -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				2  { Invoke-TerraformGet -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				3  { Invoke-TerraformPlan -WorkingDir $ProjectDirectory -Lock $false; Show-TerraformMenu }
				4  { Invoke-TerraformApply -WorkingDir $ProjectDirectory -AutoApprove $true; Show-TerraformMenu }
				5  { Invoke-TerraformCustom -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				$i { break }
		}
	}
	function Exit-TerraformDeployment {
		Write-Host -Object "`nExit Terraform project deployment...`n" -ForegroundColor DarkGray
		Start-Sleep -Seconds 1
		exit
	}
}

process {
	$Error.Clear()
	Enter-TerraformDeployment
	Show-ProjectsMenu
	Show-TerraformMenu
	Exit-TerraformDeployment
}
