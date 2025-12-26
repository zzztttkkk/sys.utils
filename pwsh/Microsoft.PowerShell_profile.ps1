$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$global:proxy = "";
$global:pyenv = $null;

function useproxy() {
	$env:http_proxy = $global:proxy
	$env:https_proxy = $global:proxy
	$env:HTTP_PROXY = $global:proxy
	$env:HTTPS_PROXY = $global:proxy
}

function unsetproxy() {
	$env:http_proxy = $null
	$env:https_proxy = $null
	$env:HTTP_PROXY = $null
	$env:HTTPS_PROXY = $null
}

function loop() {
	param (
		[string] $cmd,
		[Int] $times,
		[Int] $sleep = 1
	)

	for ($i = 1; $i -le $times; $i++) {
		Invoke-Expression $cmd
		if ($sleep -gt 0) {
			Start-Sleep -Seconds $sleep
		}
	}
}

function urandom() {
	param (
		[Int] $length = 16
	)
	python -c "print(__import__('base64').b64encode(__import__('os').urandom($length)).decode()[:$length])"
}

function uuid() {
	param (
		[switch] $random
	)
	$version = if ($random) { 4 } else { 7 }
	python -c "print(__import__('uuid').uuid$version())"
}

function confirm() {
	param (
		[string] $msg = "Are you sure?"
	)
	gum confirm $msg 
	if ($LASTEXITCODE -eq 0) {
		return $true
	}
	return $false
}

function hex() {
	param (
		$val
	)
	$tmp = "$val"
	if (-not($tmp -match "^\d+$")) {
		throw "input must be a unsigned int"
	}
	$val = [Convert]::ToInt64($tmp);
	return "0x$($val.ToString("X"))"
}

function unhex {
	param (
		[string]$val
	)
	$tmp = $val.ToLower()
	if (-not($tmp.StartsWith("0x"))) {
		$tmp = "0x$tmp"
	}
	$val = [Convert]::ToInt64($tmp, 16)
	return $val
}

. $PSScriptRoot/px.ps1
. $PSScriptRoot/env.ps1
. $PSScriptRoot/git.ps1
. $PSScriptRoot/ssh.ps1
. $PSScriptRoot/vscode.ps1
if ($IsWindows) {
	. $PSScriptRoot/windows.ps1
}
if ($IsLinux) {
	. $PSScriptRoot/linux.ps1
}
if (Get-Command docker -ErrorAction SilentlyContinue) {
	. $PSScriptRoot/docker.ps1
}

function reloadrc {
	$rc = "$HOME/.pwshrc.ps1"
	if (Test-Path -Path $rc) {
		. $rc
	}

	if (Get-Command carapace -ErrorAction SilentlyContinue) {
		Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
		Set-PSReadlineKeyHandler -Key Tab -Function MenuComplete
		carapace _carapace | Out-String | Invoke-Expression
	}

	if (($null -ne $global:pyenv) -and (Test-Path -Path $global:pyenv)) {
		& $global:pyenv\Scripts\activate.ps1
	}
}

function editrc {
	$rc = "$HOME/.pwshrc.ps1"

	$editors = @("hx", "vim", "vi", "nano")
	$editor = $null
	foreach ($e in $editors) {
		if (Get-Command $e -ErrorAction SilentlyContinue) {
			$editor = $e
			break
		}
	}
	if ($null -ne $editor) {
		& $editor $rc
		reloadrc
		return
	}		
	Write-Output "no editor found"
}

reloadrc
