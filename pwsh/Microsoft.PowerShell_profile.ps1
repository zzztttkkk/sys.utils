$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

if (-not (Get-Command cls -ErrorAction SilentlyContinue)) {
	Set-Alias cls Clear-Host
}

$global:proxy = "";
$global:pyenv = $null;
$global:editor = "vi"

function script:_detect_editor {
	$editors = @("hx", "vim", "vi", "nano")
	$editor = $null
	foreach ($e in $editors) {
		if (Get-Command $e -ErrorAction SilentlyContinue) {
			$editor = $e
			break
		}
	}
	$global:editor = $editor
}

_detect_editor

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

function script:ptop {
	param (
		[Alias("t")]
		[string] $test = ".ptop",

		[Alias("g")]
		[switch] $git
	)

	if ($git) {
		$root = $(git rev-parse --show-toplevel)
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

$script:fzfok = Get-Command fzf -ErrorAction SilentlyContinue

function x {
	$historyFile = (Get-PSReadLineOption).HistorySavePath
	if (Test-Path $historyFile) {
		$history = Get-Content $historyFile -Tail 1000 | Select-Object -Unique
		[array]::Reverse($history)
		$command = ""
		if ($fzfok) {
			$command = $history | fzf
		}
		else {
			$command = gum filter --height 15 $history
		}
		if ([string]::IsNullOrEmpty($command)) {
			return
		}
		Invoke-Expression $command
	}
}

. $PSScriptRoot/py.ps1
. $PSScriptRoot/px.ps1
. $PSScriptRoot/env.ps1
. $PSScriptRoot/git.ps1
. $PSScriptRoot/ssh.ps1
. $PSScriptRoot/vscode.ps1
. $PSScriptRoot/hosts.ps1
. $PSScriptRoot/modules.ps1
if ($IsWindows) {
	. $PSScriptRoot/windows.ps1
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

function script:reloadrc {
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
	& $global:editor $rc
	reloadrc
}

reloadrc
