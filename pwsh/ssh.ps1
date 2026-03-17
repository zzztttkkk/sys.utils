$global:__sshcAuthMap = @{};
$global:__sshcPortMap = @{};

# ssh connect
function global:sshc {
	param (
		[String] $name
	)

	$port = $global:__sshcPortMap[$name]
	if (!$port) {
		$port = 22 
	}

	$auth = $global:__sshcAuthMap[$name]
	if (!$auth) {
		Write-Output "empty auth for $name"
		return
	}

	ssh $auth -p $port $args
}

# ssh upload
function global:sshup([String] $name, [String] $local, [String] $remote) {
	$temp = $global:__sshcAuthMap[$name]
	if (!$temp) {
		Write-Output "empty auth for $name"
		return
	}

	$port = $global:__sshcPortMap[$name]
	if ( !$port ) {
		$port = 22 
	}

	$print_remote = $false;
	if ([string]::IsNullOrEmpty($remote)) {
		$remote = "/tmp/" + [guid]::NewGuid().ToString();
		$print_remote = $true;
	}
	$temp = $temp + ":" + $remote
	scp -P $port $local $temp
	if ($LASTEXITCODE -ne 0) {
		throw "scp failed"
	}
	if ($print_remote) {
		Write-Output "Remote: $remote"
	}
}

# ssh download
function script:_sshdown([String] $name, [String] $remote, [String] $local) {
	$temp = $global:__sshcAuthMap[$name]
	if (!$temp) {
		throw "empty auth for $name"
	}

	$port = $global:__sshcPortMap[$name]
	if ( !$port ) {
		$port = 22 
	}

	if ([string]::IsNullOrEmpty($local)) {
		$local = $env:USERPROFILE + "/Downloads/" + [guid]::NewGuid().ToString();
	}

	$temp = $temp + ":" + $remote
	scp -P $port $temp $local
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
	$local = script:_sshdown $name $remote $local
	Write-Output (Get-Content $local)
	Remove-Item $local
}
