Set-Alias which Get-Command
Set-Alias grep Select-String
Set-Alias ll ls

function rdps {
    $names = Get-ChildItem -Path ~/Documents/ -Filter "*.rdp" | Select-Object -ExpandProperty Name
    if ($names.Count -eq 0) {
        Write-Output "no rdp files found"
        return
    }
    if ($names.Count -eq 1) {
        $name = "$names"
    }
    else {
        $name = gum choose $names
    }
    if ([string]::IsNullOrEmpty($name)) {
        return
    }
    $path = resolve-path ~/Documents/$name
    mstsc.exe $path /w:1920 /h:1080
}

function nc() {
    param(
        [string] $_host,
        [int] $_port
    )

    Test-NetConnection -ComputerName $_host -Port $_port -InformationLevel Quiet
}

function tcpports() {
    netstat -ano -p TCP | grep LISTENING
}

function netreset() {
    $tasks = {
        ipconfig /flushdns
        ipconfig /registerdns
        ipconfig /release
        ipconfig /renew
        netsh winsock reset
    }
    sudo pwsh $tasks
}



function cclr() {
    # python
    Write-Output ">>>>>>>>>>>> pip <<<<<<<<<<<<<<<"
    pip cache purge

    # node
    Write-Output ">>>>>>>>>>>> npm <<<<<<<<<<<<<<<"
    npm cache clean --force
    Write-Output ">>>>>>>>>>>> pnpm <<<<<<<<<<<<<<<"
    pnpm cache delete
    pnpm store prune
    $nodegyp = "$HOME/AppData/Local/node-gyp"
    if (Test-Path $nodegyp) {
        Remove-Item -Recurse -Force $nodegyp
    }

    # go
    Write-Output ">>>>>>>>>>>> go <<<<<<<<<<<<<<<"
    go clean -cache
    $gopls = "$HOME/AppData/Local/gopls"
    if (Test-Path $gopls) {
        Remove-Item -r -fo $gopls
    }

    # rust
    Write-Output ">>>>>>>>>>>> rust <<<<<<<<<<<<<<<"
    cargo cache -a

    # system
    Write-Output ">>>>>>>>>>>> system <<<<<<<<<<<<<<<"
    Remove-Item -Recurse -Force "$env:TEMP/*" -ErrorAction SilentlyContinue

    # scoop
    Write-Output ">>>>>>>>>>>> scoop <<<<<<<<<<<<<<<"
    scoop cache rm *
}
