Import-Module "$PSScriptRoot/modules.psm1"

ensuremodule "toml"

Import-Module "$PSScriptRoot/config.psm1"

$Global:ProfileConfig.load()	

$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

if (-not (Get-Command cls -ErrorAction SilentlyContinue)) {
	Set-Alias cls Clear-Host
}

if ($Global:__EXEC_GUARDS_354Dh6YNpCwa) {
}
else {
	$Global:__EXEC_GUARDS_354Dh6YNpCwa = $true

	. $PSScriptRoot/crossutils.ps1
	. $PSScriptRoot/px.ps1
	. $PSScriptRoot/env.ps1
	. $PSScriptRoot/git.ps1
	. $PSScriptRoot/ssh.ps1
	. $PSScriptRoot/vscode.ps1
	. $PSScriptRoot/hosts.ps1
	. $PSScriptRoot/go.ps1
	. $PSScriptRoot/py.ps1
	if ($IsWindows) {
		. $PSScriptRoot/windows.ps1
		if (Get-Command llama-server -ErrorAction SilentlyContinue) {
			. $PSScriptRoot/llm.ps1
		}
	}
	if ($IsLinux) {
		. $PSScriptRoot/linux.ps1
	}
	if ($IsMacOS) {
		. $PSScriptRoot/mac.ps1
	}
	if (Get-Command docker -ErrorAction SilentlyContinue) {
		. $PSScriptRoot/docker.ps1
	}
}

if (($Host.UI.RawUI.WindowSize.Width -lt 50) -or ($Host.UI.RawUI.WindowSize.Height -lt 5)) {
}
else {
	ensuremodule "readline"
	Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
	Set-PSReadLineOption -PredictionSource HistoryAndPlugin
	Set-PSReadLineOption -PredictionViewStyle ListView
	Remove-PSReadLineKeyHandler -Key F2
	Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

function script:reloadrc {
	$rc = "$HOME/.pwshrc.ps1"
	if (Test-Path -Path $rc) {
		. $rc
	}
}

function editrc {
	$rc = "$HOME/.pwshrc.ps1"
	& $global:ProfileConfig.editor $rc
	reloadrc
}

reloadrc
