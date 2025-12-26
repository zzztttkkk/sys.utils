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
	if ($print_remote) {
		Write-Output "Remote: $remote"
	}
}

# ssh download
function global:sshdown([String] $name, [String] $remote, [String] $local) {
	$temp = $global:__sshcAuthMap[$name]
	if (!$temp) {
		Write-Output "empty auth for $name"
		return
	}

	$port = $global:__sshcPortMap[$name]
	if ( !$port ) {
		$port = 22 
	}

	$print_local = $false;
	if ([string]::IsNullOrEmpty($local)) {
		$local = $env:USERPROFILE + "/Downloads/" + [guid]::NewGuid().ToString();
		$print_local = $true;
	}

	$temp = $temp + ":" + $remote
	scp -P $port $temp $local
	if ($print_local) {
		Write-Output "Local: $local"
	}
}