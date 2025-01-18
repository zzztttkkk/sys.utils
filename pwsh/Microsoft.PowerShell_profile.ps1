& $HOME/.pyenv/Scripts/activate.ps1
fnm env --use-on-cd | Out-String | Invoke-Expression

Set-Alias which Get-Command
Set-Alias grep Select-String
Set-Alias ll ls

$global:proxy = "";

function useproxy() {
	$env:http_proxy = $global:proxy
	$env:https_proxy = $global:proxy
}

function unsetproxy() {
	$env:http_proxy = ""
	$env:https_proxy = ""
}

function nc() {
	param(
		[string] $_host,
		[int] $_port
	)

	Test-NetConnection -ComputerName $_host -Port $_port
}

# explorer.exe
function fexp {
	param (
		[string]$target = "."
	)
	$path = resolve-path $target
	explorer.exe $path
}

function fexprestar() {
	taskkill /f /im explorer.exe
	Start-Process explorer.exe
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

	if ($outputtype -eq "") {
		$outputtype = &gum choose --selected="hex" "base64" "bin" "hex" 
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

function listeningports() {
	netstat -ano -p TCP | grep LISTENING
}

function netreset() {
	ipconfig /flushdns
	ipconfig /registerdns
	ipconfig /release
	ipconfig /renew
	netsh winsock reset
}
function fkill() {
	param (
		[String] $val = "",
		[String] $prop = "ProcessName",
		[String] $op = "eq"
	)
	if ($val -eq "" ) {
		return
	}
	$op = "-${op}"
	$operators = @('-eq', '-ne', '-gt', '-lt', '-ge', '-le', '-like', '-notlike', '-match', '-notmatch', '-in', '-notin', '-and', '-or', '-not', '-is', '-isnot', '-ceq', '-cne', '-cgt', '-clt', '-cge', '-cle', '-clike', '-cnotlike', '-cmatch', '-cnotmatch')
	if ($operators -notcontains $op) {
		throw "bad operator: $op"
	}
	$ids = Invoke-Expression "ps | where -Property $prop -Value $val $op | select -ExpandProperty Id"
	foreach ( $tmpid in $ids ) {
		try {
			stop-process -id $tmpid
		}
		catch {
			Write-Warning "Failed to terminate process: $tmpid"
		}
	}
}

function cacheclean() {
	# node
	Write-Output ">>>>>>>>>>>> npm <<<<<<<<<<<<<<<"
	npm cache clean --force
	Write-Output ">>>>>>>>>>>> pnpm <<<<<<<<<<<<<<<"
	pnpm cache delete
	pnpm store prune
	try {
		Write-Output ">>>>>>>>>>>> nodegyp <<<<<<<<<<<<<<<"
		Remove-Item -r -fo ~/AppData/Local/node-gyp
	}
	catch {
		""
	}

	# go
	Write-Output ">>>>>>>>>>>> go <<<<<<<<<<<<<<<"
	go clean -cache
	try {
		Write-Output ">>>>>>>>>>>> gopls <<<<<<<<<<<<<<<"
		Remove-Item -r -fo ~/AppData/Local/gopls
	}
	catch {
		""
	}

	# rust
	Write-Output ">>>>>>>>>>>> rust <<<<<<<<<<<<<<<"
	cargo cache -a
}

. $PSScriptRoot/git.ps1
. $PSScriptRoot/ssh.ps1
. $PSScriptRoot/vscode.ps1

$local = "$PSScriptRoot/local.ps1"
if (Test-Path -Path $local) {
	. $local
}

if ( ! $global:__code_projects_dir ) {
	$global:__code_projects_dir = "d:/codes"
}
