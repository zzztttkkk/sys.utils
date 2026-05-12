function useproxy() {
    $proxy = $Global:ProfileConfig.proxy
    $env:http_proxy = $proxy
    $env:https_proxy = $proxy
    $env:HTTP_PROXY = $proxy
    $env:HTTPS_PROXY = $proxy
}

function unsetproxy() {
    $env:http_proxy = $null
    $env:https_proxy = $null
    $env:HTTP_PROXY = $null
    $env:HTTPS_PROXY = $null
}

function loop() {
    param (
        [Parameter(Mandatory = $true)]
        [scriptblock] $cmd,
        [Int] $times = 1,
        [Int] $sleep = 1
    )

    for ($i = 1; $i -le $times; $i++) {
        & $cmd
        if ($sleep -gt 0) {
            Start-Sleep -Seconds $sleep
        }
    }
}

function urandom() {
    param (
        [Int] $length = 16
    )

    $alphabet = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
    $alphabetLength = $alphabet.Length
    
    $result = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $length; $i++) {
        $index = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($alphabetLength)
        [void]$result.Append($alphabet[$index])
    }
    return $result.ToString()
}

function uuid() {
    param (
        [switch] $random
    )
    if ($random) { return [guid]::NewGuid().ToString() }
    return [guid]::CreateVersion7().ToString()
}

function confirm() {
    param (
        [string] $msg = "Are you sure?"
    )
    gum confirm $msg 
    if ($LASTEXITCODE -eq 0) {
        return $true
    }
    return $false
}

function fexp {
    param (
        [string]$target = ".",
        [alias("q")]
        [switch]$quick = $false
    )
    if ($target -eq ".") {
        if ($quick) {
            $bookmarkets = $Global:ProfileConfig.fexpbookmarkets
            $key = gum filter $bookmarkets.Keys
            if ([string]::IsNullOrEmpty($key)) {
                return;
            }
            $target = $bookmarkets[$key];
        }
    }
    if ([string]::IsNullOrEmpty($target)) {
        return;
    }
    $path = Resolve-Path $target
    $exe = ""
    if ($IsWindows) {
        $exe = "explorer.exe"
    }
    if ($IsLinux) {
        $exe = "xdg-open"
    }
    if ($IsMacOS) {
        $exe = "open"
    }
    & $exe $path
}

function script:ptop {
    param (
        [Alias("t")]
        [string] $test = ".ptop",

        [Alias("g")]
        [switch] $git
    )

    if ($git) {
        $root = $(git rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -ne 0) {
            return
        }
        Set-Location $root
        return
    }

    $current = (Get-Location).Path
    while (1) {
        if (Test-Path -Path "$current/$test") {
            Set-Location $current
            return
        }
        $tmp = $current
        $current = Split-Path -Path $current -Parent -ErrorAction SilentlyContinue
        if ($tmp -eq $current) {
            break
        }
        if ([string]::IsNullOrEmpty($current)) {
            break
        }
    }

    Write-Output "ptop failed"
    return
}

function z {
    param (
        [string] $dest,

        [Alias("g")]
        [switch] $git,

        [Alias("t")]
        [string] $test
    )

    switch ($dest) {
        "g" { 
            $git = $true
            $dest = $null
        }
        Default {}
    }
	
    if (-not [string]::IsNullOrEmpty($dest)) {
        Set-Location $dest
        return
    }

    if ($git) {
        ptop -g
        return
    }

    if ($test) {
        ptop -t $test
        return
    }

    ptop
}

# filter kill
function fq() {
    param (
        [String[]] $vals,
        [String] $op = "eq"
    )
    if (($null -eq $vals) -or ($vals.Length -eq 0)) {
        return
    }
    $procs = Get-Process | Where-Object -FilterScript {
        $pn = $($_.ProcessName)
        foreach ($val in $vals) {
            switch ($op) {
                "eq" { 
                    if ($pn -eq $val) {
                        return $true
                    }
                }
                "like" {
                    if ($pn -like $val) {
                        return $true                        
                    }
                }
                "match" {
                    if ($pn -match $val) {
                        return $true
                    }
                }
                Default {
                    return $false
                }
            }
        }
        return $false
    }
    foreach ( $proc in $procs ) {
        Write-Host "kill process: $($proc.Name) $($proc.Id)"
        Stop-Process -id $proc.Id -ErrorAction SilentlyContinue
    }
}