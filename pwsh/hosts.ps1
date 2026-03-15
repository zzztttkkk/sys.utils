function global:edithosts {
    if ($IsWindows) {
        & $global:editor $env:windir\System32\drivers\etc\hosts
        return
    }
    & sudo $global:editor /etc/hosts
}