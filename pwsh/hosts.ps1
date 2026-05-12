function global:edithosts {
    $editor = $global:ProfileConfig.editor
    if ($IsWindows) {
        $cmd = "$editor $env:windir\System32\drivers\etc\hosts" 
        sudo pwsh -c $cmd
        return
    }
    & sudo $editor /etc/hosts
}