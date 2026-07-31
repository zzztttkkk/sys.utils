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

function hvrun {
    param (
        [Alias("c")]
        [switch] $connect
    )

    sudo pwsh -NoProfile -c {
        $c = $args[0]["c"]

        $items = @(Get-VM | Where-Object { $_.State -eq "Off" } | Select-Object -ExpandProperty Name)
        if ($items.Count -lt 1) { return; }
        
        $name = gum filter $items
        if ([string]::IsNullOrEmpty($name)) { return; }

        Start-VM -Name $name
        if ($c) {
            Start-Process vmconnect -ArgumentList "localhost", $name
        }
    } -args @{ c = $connect }
}

function cclr() {
    # node
    Write-Output ">>>>>>>>>>>> npm <<<<<<<<<<<<<<<"
    npm cache clean --force
    Write-Output ">>>>>>>>>>>> pnpm <<<<<<<<<<<<<<<"
    pnpm cache delete
    pnpm store prune

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

    #python
    Write-Output ">>>>>>>>>>>> uv <<<<<<<<<<<<<<<"
    uv cache clean
    
    #fnm
    Write-Output ">>>>>>>>>>>> fnm <<<<<<<<<<<<<<<"
    & {
        $c = $env:FNM_MULTISHELL_PATH
        if (Test-Path $c) {
            $p = Split-Path -Path $c -Parent
            Get-ChildItem -Path $p -Directory | Remove-Item -Recurse -Force
        }
    }
}