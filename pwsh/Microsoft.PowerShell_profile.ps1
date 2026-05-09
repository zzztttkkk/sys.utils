Import-Module "$PSScriptRoot/modules.psm1"

ensuremodule "toml"

Import-Module "$PSScriptRoot/config.psm1"

function reloadcfg {
	$Global:ProfileConfig.load()	
}

reloadcfg

$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

if (-not (Get-Command cls -ErrorAction SilentlyContinue)) {
	Set-Alias cls Clear-Host
}

function useproxy() {
	$proxy = $Global:ProfileConfig.proxy
	$env:http_proxy = $proxy
	$env:https_proxy = $proxy
	$env:HTTP_PROXY = $proxy
	$env:HTTPS_PROXY = $proxy
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
	pip show based58 | Out-Null
	if ($LASTEXITCODE -ne 0) {
		pip install based58
	}
	python -c "print(__import__('based58').b58encode(__import__('os').urandom($length)).decode()[:$length])"
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

function fexp {
	param (
		[string]$target = ".",
		[alias("q")]
		[switch]$quick = $false
	)
	if ($target -eq ".") {
		if ($quick) {
			$bookmarkets = $Global:ProfileConfig.fexpbookmarkets
			$key = gum filter $bookmarkets.Keys
			if ([string]::IsNullOrEmpty($key)) {
				return;
			}
			$target = $bookmarkets[$key];
		}
	}
	if ([string]::IsNullOrEmpty($target)) {
		return;
	}
	$path = Resolve-Path $target
	$exe = ""
	if ($IsWindows) {
		$exe = "explorer.exe"
	}
	if ($IsLinux) {
		$exe = "xdg-open"
	}
	if ($IsMacOS) {
		$exe = "open"
	}
	& $exe $path
}

function script:ptop {
	param (
		[Alias("t")]
		[string] $test = ".ptop",

		[Alias("g")]
		[switch] $git
	)

	if ($git) {
		$root = $(git rev-parse --show-toplevel 2>$null)
		if ($LASTEXITCODE -ne 0) {
			return
		}
		Set-Location $root
		return
	}

	$current = (Get-Location).Path
	while (1) {
		if (Test-Path -Path "$current/$test") {
			Set-Location $current
			return
		}
		$tmp = $current
		$current = Split-Path -Path $current -Parent -ErrorAction SilentlyContinue
		if ($tmp -eq $current) {
			break
		}
		if ([string]::IsNullOrEmpty($current)) {
			break
		}
	}

	Write-Output "ptop failed"
	return
}

function z {
	param (
		[string] $dest,

		[Alias("g")]
		[switch] $git,

		[Alias("t")]
		[string] $test
	)

	switch ($dest) {
		"g" { 
			$git = $true
			$dest = $null
		}
		Default {}
	}
	
	if (-not [string]::IsNullOrEmpty($dest)) {
		Set-Location $dest
		return
	}

	if ($git) {
		ptop -g
		return
	}

	if ($test) {
		ptop -t $test
		return
	}

	ptop
}

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

ensuremodule "readline"
Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
Set-PSReadLineOption -PredictionSource HistoryAndPlugin
Set-PSReadLineOption -PredictionViewStyle ListView
Set-PSReadLineOption -DisableWindowSizeWarning $true
Remove-PSReadLineKeyHandler -Key F2
Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete

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
