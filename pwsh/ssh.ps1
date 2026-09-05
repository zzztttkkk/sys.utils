Import-Module "$PSScriptRoot/config.psm1"

function script:pickname() {
	param (
		[String] $name
	)
	if ([string]::IsNullOrEmpty($name)) {
		$keys = $global:ProfileConfig.ssh.auths.Keys
		$name = gum filter $keys
	}
	return $name
}

# ssh connect
function global:sshc {
	param (
		[String] $name,
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]] $remains = @()
	)
	$name = pickname $name
	if ([string]::IsNullOrEmpty($name)) { return; }

	$port = $global:ProfileConfig.ssh.ports[$name]
	if (-not $port) {
		$port = 22
	}

	$auth = $global:ProfileConfig.ssh.auths[$name]
	if (-not $auth) {
		Write-Output "empty auth for $name"
		return
	}

	ssh $auth -p $port $remains
}

# ssh upload
function global:sshup([String] $name, [String] $local, [String] $remote) {
	$name = pickname $name
	if ([string]::IsNullOrEmpty($name)) { return; }

	$temp = $global:ProfileConfig.ssh.auths[$name]
	if (-not $temp) {
		Write-Output "empty auth for $name"
		return
	}

	$port = $global:ProfileConfig.ssh.ports[$name]
	if (-not $port) {
		$port = 22
	}

	$print_remote = $false;
	if ([string]::IsNullOrEmpty($remote)) {
		$remote = "/tmp/" + [guid]::NewGuid().ToString();
		$print_remote = $true;
	}
	$temp = $temp + ":" + $remote
	$scpargs = @("-P", $port, $local, $temp)
	scp $scpargs
	if ($LASTEXITCODE -ne 0) {
		throw "scp failed"
	}
	if ($print_remote) {
		Write-Output "Remote: $remote"
	}
}

# ssh download
function script:_sshdown([String] $name, [String] $remote, [String] $local) {
	$temp = $global:ProfileConfig.ssh.auths[$name]
	if (!$temp) {
		throw "empty auth for $name"
	}

	$port = $global:ProfileConfig.ssh.ports[$name]
	if (-not $port) {
		$port = 22
	}

	if ([string]::IsNullOrEmpty($local)) {
		$leaf = Split-Path $remote -Leaf
		$local = "$HOME/Downloads/$leaf"
	}

	$temp = $temp + ":" + $remote
	$scpargs = @("-q", "-P", $port, $temp, $local)
	scp $scpargs
	return $local
}

function global:sshdown {
	param (
		[String] $name,
		[String] $remote,
		[String] $local
	)
	$local = _sshdown $name $remote $local
	if ($LASTEXITCODE -ne 0) {
		throw "scp failed"
	}
	Write-Output "Local: $local"
}

function global:sshcat {
	param (
		[String] $name,
		[String] $remote
	)
	$local = _sshdown $name $remote ""
	if ($LASTEXITCODE -ne 0) {
		throw "scp failed"
	}
	Write-Output (Get-Content $local)
	Remove-Item $local
}

function script:clipr {
	$content = ""
	if ($IsWindows) {
		$content = Get-Clipboard -Raw
	}
	elseif ($IsLinux) {
		$content = wl-paste 2>$null
	}
	elseif ($IsMacOS) {
		$content = pbpaste 2>$null
	}
	return $content
}

function script:clipw($content) {
	if ($IsWindows) {
		Set-Clipboard $content
		return
	}
	if ($IsLinux) {
		$content | wl-copy
		return
	}
	if ($IsMacOS) {
		$content | pbcopy
		return
	}
}

function global:sclipw {
	param (
		[String] $name
	)
	$name = pickname $name
	$content = clipr
	if ([string]::IsNullOrEmpty($content)) {
		Write-Warning "failed to read clipboard"
	}
	$content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
	sshc $name "echo '$content' > ~/.sshclipboard.temp"
}

function global:sclipr {
	param (
		[String] $name
	)
	$name = pickname $name
	if ([string]::IsNullOrEmpty($name)) { return; }

	$raw = (@(sshc $name "cat ~/.sshclipboard.temp") -join "").Trim()
	if ([string]::IsNullOrEmpty($raw)) {
		Write-Warning "empty remote clipboard: $name"
		return
	}

	$bytes = $null
	try {
		$bytes = [Convert]::FromBase64String($raw)
	}
	catch {
		Write-Warning "invalid remote clipboard content: $($_.Exception.Message)"
		return
	}

	$content = [System.Text.Encoding]::UTF8.GetString($bytes)
	clipw $content
}
