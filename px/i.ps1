function script:install_pwsh {
    $target = ""
    if ($IsWindows) {
        $target = "$HOME/Documents/PowerShell"
    }
    else {
        $target = "$HOME/.config/powershell"
    }

    Remove-Item -Recurse -Force $target -ErrorAction SilentlyContinue
    if (!(Test-Path $target)) {
        New-Item -ItemType Directory $target
    }
    Copy-Item -Recurse -Path ./pwsh -Destination $target
}

function script:install_ahk {
    if(!$IsWindows){
        return;
    }
    $target = "$HOME//AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/"
    Copy-Item -Path ./files/.ahk -Destination $target/.ahk
}


install_pwsh
install_ahk
