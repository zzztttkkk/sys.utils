$script:notty = ($env:SSH_CLIENT -and (-not $env:SSH_TTY)) -or ($null -eq $Host.UI.RawUI);

if ($notty) {  }
else {
	if ($global:__EXEC_GUARDS_354Dh6YNpCwa) {
		return
	}
	$global:__EXEC_GUARDS_354Dh6YNpCwa = $true
	. $PSScriptRoot/profile.ps1
}
