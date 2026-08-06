Import-Module "$PSScriptRoot/modules.psm1"

ensuremodule "toml"

Import-Module "$PSScriptRoot/config.psm1"

$Global:ProfileConfig.load()	

$OutputEncoding = [System.Console]::OutputEncoding = [System.Console]::InputEncoding = [System.Text.Encoding]::UTF8
$PSDefaultParameterValues['*:Encoding'] = 'utf8'

if (-not (Get-Command cls -ErrorAction Ignore)) {
    Set-Alias cls Clear-Host
}

. $PSScriptRoot/crossutils.ps1
. $PSScriptRoot/px.ps1
. $PSScriptRoot/env.ps1
. $PSScriptRoot/git.ps1
. $PSScriptRoot/ssh.ps1
. $PSScriptRoot/vscode.ps1
. $PSScriptRoot/go.ps1
. $PSScriptRoot/py.ps1
. $PSScriptRoot/llm.ps1
. $PSScriptRoot/s3.ps1
. $PSScriptRoot/aes.ps1
	
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

function script:enablereadline {
    if ($null -eq $Host.UI.RawUI) { return; }
    if ($Host.UI.RawUI.WindowSize.Width -lt 50) { return; }
    if ($Host.UI.RawUI.WindowSize.Height -lt 5) { return; }

    ensuremodule "readline"
    Set-PSReadLineOption -Colors @{ "Selection" = "`e[7m" }
    Set-PSReadLineOption -PredictionSource HistoryAndPlugin
    Set-PSReadLineOption -PredictionViewStyle ListView
    Remove-PSReadLineKeyHandler -Key F2
    Set-PSReadLineKeyHandler -Key Tab -Function MenuComplete
}

enablereadline

function script:reloadrc {
    $rc = "$HOME/.pwshrc.ps1"
    if (Test-Path -Path $rc) {
        . $rc
    }
}

function script:ep {
    param (
        [switch] $code = $false
    )
    $ep = $global:ProfileConfig.editor
    if ($code) {
        $ep = "code"
    }
    return $ep
}

function editrc {
    param (
        [switch] $code = $false
    )
    $epv = @{ code = $code }
    & $(ep @epv) "$HOME/.pwshrc.ps1"
    if ($code) { return; }
}

function editmycfg {
    param (
        [switch] $code = $false
    )
    $epv = @{ code = $code }
    & $(ep @epv) "$HOME/.pwsh.profile.toml"
    if ($code) { return; }
    $Global:ProfileConfig.load();
}

reloadrc
