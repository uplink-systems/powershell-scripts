<#PSScriptInfo
    .VERSION 1.0.0.0
    .GUID acc3d970-a584-47f9-a475-462842c02373
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
    .NOTES
        Version:        1.0.0.0
        Author:         Andreas Schreiner
        Copyright:      Andreas Schreiner IT Services
        Creation Date:  06.02.2025
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
		https://github.com/uplink-systems/powershell-scripts/HashiCorp/Terraform/
	.LINK
		https://github.com/uplink-systems/powershell-modules/Modules/UplinkSystems.Terraform/
#>

#Requires -Version 7.0

begin {
	$TerraformPsModule = 'UplinkSystems.Terraform'
	function Enter-TerraformDeployment {
		Write-Host -Object "`nEnter new or existing Terraform project deployment..." -ForegroundColor DarkGray
		Start-Sleep -Seconds 2
		try {
			Import-Module -Name $TerraformPsModule -Force -ErrorAction Stop
			Write-Host -Object "Importing UplinkSystems.Terraform module for PowerShell... " -ForegroundColor DarkGray -NoNewline
			Write-Host -Object "Success..." -ForegroundColor Green
			Start-Sleep -Seconds 2
		}
		catch [System.IO.DirectoryNotFoundException],[System.IO.FileNotFoundException] {
			Write-Host -Object "`nImporting UplinkSystems.Terraform module for PowerShell... " -ForegroundColor DarkGray -NoNewline
			Write-Host -Object "Failed... " -ForegroundColor Red -NoNewline
			Write-Host -Object "Module not found...." -ForegroundColor White
			Start-Sleep -Seconds 2
			Exit-TerraformDeployment
		}
		catch {
			Write-Host -Object "`nImporting UplinkSystems.Terraform module for PowerShell... " -ForegroundColor DarkGray -NoNewline
			Write-Host -Object "Failed... " -ForegroundColor Red -NoNewline
			Start-Sleep -Seconds 2
			Exit-TerraformDeployment
		}
	}
	function Show-ProjectsMenu {
		$ProjectsDirectories = Get-ChildItem -Path $PSScriptRoot -Directory | Select-Object Name
		$ProjectsMenu = @{}
		Write-Host -Object "`n=============== Select Terraform Project ======================"
		Write-Host
		for ($i=1; $i -le $ProjectsDirectories.Count; $i++) {
			Write-Host -Object "$i > $($ProjectsDirectories[$i-1].Name)" 
			$ProjectsMenu.Add($i,($ProjectsDirectories[$i-1].Name))
		}
		Write-Host -Object "`n==============================================================="
		[int]$ans = Read-Host 'Select Option'
		$Global:ProjectDirectory = $ProjectsMenu.Item($ans)
		if ($null -eq $ProjectDirectory) {
			Write-Host -Object "`nSelection (" -NoNewline -ForegroundColor DarkGray
			Write-Host -Object "'$ans'" -NoNewline -ForegroundColor White
			Write-Host -Object ") is not valid for an available Terraform project... Exit deployment...`n" -ForegroundColor DarkGray
			Start-Sleep -Seconds 3
			exit
		} else {
			Write-Host -Object "`n$($ProjectDirectory) " -ForegroundColor White -NoNewline
			Write-Host -Object "is the selected Terraform project..." -ForegroundColor DarkGray
			Start-Sleep -Seconds 3
		}
	}
	function Show-TerraformMenu {
		$TerraformTasks = @(
			"Initialize  -> terraform init"
			"Initialize  -> terraform init -upgrade"
			"Plan        -> terraform plan"
			"Plan        -> terraform plan -out"
			"Apply       -> terraform apply"
			"Destroy     -> terraform plan -destroy"
			"Destroy     -> terraform apply -destroy"
			"Custom Task -> terraform <custom task/attribute list>"
			"EXIT"
		)
		do {
			$i = 1
			Write-Host "`n============== Select Terraform Task =========================="
			Write-Host
			$TerraformTasks | ForEach-Object { Write-Host -Object "$i > $_" ; if ($i -lt $TerraformTasks.Count){$i ++} }
			Write-Host "`n==============================================================="
			$Global:TerraformTask = Read-Host "Select Option"
		} until (($null -ne $TerraformTask -as [int]) -and ($TerraformTask -ge 1 -le $i))
		switch ($TerraformTask) {
				1  		{ Invoke-TerraformInit -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				2  		{ Invoke-TerraformInit -WorkingDir $ProjectDirectory -Upgrade $true; Show-TerraformMenu }
				3  		{ Invoke-TerraformPlan -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				4  		{ Invoke-TerraformPlan -WorkingDir $ProjectDirectory -Out $true; Show-TerraformMenu }
				5  		{ Invoke-TerraformApply -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				6  		{ Invoke-TerraformDestroy -WorkingDir $ProjectDirectory; Show-TerraformMenu }
				7  		{ Invoke-TerraformDestroy -WorkingDir $ProjectDirectory -DryRun $false; Show-TerraformMenu }
				8  		{ Invoke-TerraformCustom -WorkingDir $ProjectDirectory; Start-Sleep -Seconds 2; Show-TerraformMenu }
				$i 		{ Exit-TerraformDeployment }
				Default	{ Exit-TerraformDeployment }
		}
	}
	function Exit-TerraformDeployment {
		Write-Host -Object "`nCleaning up and exit Terraform project deployment...`n" -ForegroundColor DarkGray
		Invoke-TerraformWorkingDirectoryCleanup -WorkingDir $ProjectDirectory
		Start-Sleep -Seconds 2
		exit
	}
}

process {
	$Error.Clear()
	Enter-TerraformDeployment
	Test-TerraformRequirement; Start-Sleep -Seconds 2
	Show-ProjectsMenu
	Show-TerraformMenu
	Exit-TerraformDeployment
}
