$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

$global:proxy = "";

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
		[Int] $times
	)

	for ($i = 1; $i -le $times; $i++) {
		&$args[0] ($args | select-object -skip 1)
	}
}

function urandom() {
	param (
		[Int] $length = 16
	)
	python -c "print(__import__('base64').b64encode(__import__('os').urandom($length)).decode()[:$length])"
}

function hash() {
	param (
		[String] $txt = "",
		[String] $algname = "",
		[String] $outputtype = ""
	)

	if ($txt -eq "") {
		$txt = &gum input --placeholder="input some text in utf8"
	}

	if ($algname -eq "") {
		$tmp = &python -c 'print(" ".join(sorted(list(__import__("hashlib").algorithms_available))))'
		$algs = $tmp -split " "
		$algname = &gum choose --selected="md5" $algs
	}
	if ($null -eq $algname) {
		return;
	}

	if ($outputtype -eq "") {
		$outputtype = &gum choose --selected="hex" "base64" "bin" "hex" 
	}
	if ($null -eq $outputtype) {
		return;
	}

	switch ($outputtype) {
		"hex" {
			python -c "print(__import__('hashlib').$algname('''$outputtype'''.encode('utf8')).hexdigest())"
		}
		"bin" {
			python -c "print(__import__('hashlib').$algname('''$outputtype'''.encode('utf8')).digest())"
		}
		"base64" {
			python -c "print(__import__('base64').b64encode(__import__('hashlib').$algname('''$outputtype'''.encode('utf8')).digest()).decode())"
		}
	}
	
}

function hex() {
	param (
		[int] $num = 0
	)
	$val = "{0:X}" -f $num
	Write-Output $val
}

. $PSScriptRoot/git.ps1
. $PSScriptRoot/ssh.ps1
. $PSScriptRoot/vscode.ps1
if ($IsWindows) {
	. $PSScriptRoot/windows.ps1
}

if ($IsLinux) {
	. $PSScriptRoot/linux.ps1
}

$local = "$PSScriptRoot/local.ps1"
if (Test-Path -Path $local) {
	. $local
}

$rc = "$HOME/.pwshrc.ps1"
if (Test-Path -Path $rc) {
	. $rc
}

if(Get-Command oh-my-posh -ErrorAction SilentlyContinue){
	oh-my-posh init pwsh | Invoke-Expression
}
