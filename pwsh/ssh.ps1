Import-Module "$PSScriptRoot/config.psm1"

function script:pickname() {
	param (
		[String] $name
	)
	if ([string]::IsNullOrEmpty($name)) {
		$keys = $global:ProfileConfig.sshauths.Keys
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

	$port = $global:ProfileConfig.sshports[$name]
	if (!$port) {
		$port = 22 
	}

	$auth = $global:ProfileConfig.sshauths[$name]
	if (!$auth) {
		Write-Output "empty auth for $name"
		return
	}

	ssh $auth -p $port $remains
}

# ssh upload
function global:sshup([String] $name, [String] $local, [String] $remote) {
	$name = pickname $name
	if ([string]::IsNullOrEmpty($name)) { return; }

	$temp = $global:ProfileConfig.sshauths[$name]
	if (!$temp) {
		Write-Output "empty auth for $name"
		return
	}

	$port = $global:ProfileConfig.sshports[$name]
	if ( !$port ) {
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
	$temp = $global:ProfileConfig.sshauths[$name]
	if (!$temp) {
		throw "empty auth for $name"
	}

	$port = $global:ProfileConfig.sshports[$name]
	if ( !$port ) {
		$port = 22 
	}

	if ([string]::IsNullOrEmpty($local)) {
		$local = $HOME + "/Downloads/" + [guid]::NewGuid().ToString();
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

function global:sclipw {
	param (
		[String] $name
	)
	$name = pickname $name
	$content = Get-Clipboard -Raw
	$content = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($content))
	sshc $name "echo '$content' > ~/.sshclipboard.temp"
}

function global:sclipr {
	param (
		[String] $name
	)
	$name = pickname $name
	if ([string]::IsNullOrEmpty($name)) { return; }

	$content = sshc $name "cat ~/.sshclipboard.temp"
	$content = [Convert]::FromBase64String($content)
	$content = [System.Text.Encoding]::UTF8.GetString($content)
	Set-Clipboard $content
}
