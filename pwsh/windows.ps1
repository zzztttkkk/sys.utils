& $HOME/.pyenv/Scripts/activate.ps1

Set-Alias which Get-Command
Set-Alias grep Select-String
Set-Alias ll ls

# explorer.exe
function fexp {
    param (
        [string]$target = "."
    )
    $path = resolve-path $target
    explorer.exe $path
}

function fexprestar() {
    taskkill /f /im explorer.exe
    Start-Process explorer.exe
}

function nc() {
    param(
        [string] $_host,
        [int] $_port
    )

    Test-NetConnection -ComputerName $_host -Port $_port
}

function listeningports() {
    netstat -ano -p TCP | grep LISTENING
}

function netreset() {
    ipconfig /flushdns
    ipconfig /registerdns
    ipconfig /release
    ipconfig /renew
    netsh winsock reset
}
function fkill() {
    param (
        [String] $val = "",
        [String] $prop = "ProcessName",
        [String] $op = "eq"
    )
    if ($val -eq "" ) {
        return
    }
    $op = "-${op}"
    $operators = @('-eq', '-ne', '-gt', '-lt', '-ge', '-le', '-like', '-notlike', '-match', '-notmatch', '-in', '-notin', '-and', '-or', '-not', '-is', '-isnot', '-ceq', '-cne', '-cgt', '-clt', '-cge', '-cle', '-clike', '-cnotlike', '-cmatch', '-cnotmatch')
    if ($operators -notcontains $op) {
        throw "bad operator: $op"
    }
    $ids = Invoke-Expression "ps | where -Property $prop -Value $val $op | select -ExpandProperty Id"
    foreach ( $tmpid in $ids ) {
        try {
            stop-process -id $tmpid
        }
        catch {
            Write-Warning "Failed to terminate process: $tmpid"
        }
    }
}

function cacheclean() {
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
}

if (Test-Path -Path "C:\Program Files\Oracle\VirtualBox\VBoxManage.exe") {
    . $PSScriptRoot/vbox.ps1
}
