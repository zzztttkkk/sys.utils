$script:notty = ($env:SSH_CLIENT -and (-not $env:SSH_TTY)) -or ($null -eq $Host.UI.RawUI);

if ($notty -or $global:__EXEC_GUARDS_354Dh6YNpCwa) {  }
else {
	$global:__EXEC_GUARDS_354Dh6YNpCwa = $true
	. $PSScriptRoot/profile.ps1
}
