param (
    [string]$name
)

& $PSScriptRoot/common.ps1
& $PSScriptRoot/.1.ps1

Write-Output "hello from a.ps1, $name!"

