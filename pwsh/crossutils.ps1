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
    $result = New-Object System.Text.StringBuilder
    for ($i = 0; $i -lt $length; $i++) {
        $index = [System.Security.Cryptography.RandomNumberGenerator]::GetInt32($alphabet.Length)
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
            $marks = $Global:ProfileConfig.fexpmarks
            if ($null -eq $marks) {
                Write-Host "empty marks" -ForegroundColor Yellow
                return;
            }
            $key = gum filter $marks.Keys
            if ([string]::IsNullOrEmpty($key)) { return; }
            $target = $marks[$key];
        }
    }
    if ([string]::IsNullOrEmpty($target)) {
        return;
    }
    $target = $ExecutionContext.InvokeCommand.ExpandString($target)
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
    Start-Process $exe -ArgumentList $path
}

function global:z {
    param (
        [Alias("t")]
        [string] $test = ".z.toml",

        [Alias("g")]
        [switch] $git,
        [Alias("q")]
        [switch] $quick
    )

    if ($git) {
        $root = $(git rev-parse --show-toplevel 2>$null)
        if ($LASTEXITCODE -ne 0) {
            Write-Host "not inside a git repo" -ForegroundColor Yellow
            return
        }
        Set-Location $root
        return
    }

    if ($quick) {
        $quick = $test -eq ".z.toml"
    }

    [string]$current = (Get-Location).Path
    while (1) {
        if (Test-Path -Path "$current/$test") {
            if ($quick) {
                $fc = Get-Content "$current/$test" -Raw -Encoding utf8 | ConvertFrom-Toml -ErrorAction Stop
                [hashtable]$marks = $fc.marks
                if (($null -eq $marks) -or ($marks.Count -lt 1)) {
                    Write-Host "empty marks" -ForegroundColor Yellow
                    return;
                }
                [string]$key = gum filter $marks.Keys
                if ([string]::IsNullOrEmpty($key)) { return; }

                [string]$val = $marks[$key];
                if ($val.StartsWith("./")) {
                    $val = "$current$($val.Substring(1))"
                }
                Set-Location $val
                return;
            }
            Set-Location $current
            return
        }
        $tmp = $current
        $current = Split-Path -Path $current -Parent -ErrorAction SilentlyContinue
        if (($tmp -eq $current) -or ([string]::IsNullOrEmpty($current))) {
            break
        }
    }

    Write-Host "jump failed" -ForegroundColor Yellow
    return
}

# filter kill
function fq() {
    param (
        [String[]] $vals,
        [String] $op = "eq"
    )
    if (($null -eq $vals) -or ($vals.Length -eq 0)) { return }
    
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

function iselevated {
    if ($IsWindows) {
        return [Security.Principal.WindowsPrincipal]::new([Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator);
    }
    return (id -u) -eq 0
}

function aesencrypt {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [string] $plaintxt
    )
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Global:ProfileConfig.cryptokey
    $aes.GenerateIV()
    $encryptor = $aes.CreateEncryptor()
    $plainBytes = [System.Text.Encoding]::UTF8.GetBytes($plaintxt)
    $cipherBytes = $encryptor.TransformFinalBlock($plainBytes, 0, $plainBytes.Length)
    $resultBytes = $aes.IV + $cipherBytes
    return [Convert]::ToBase64String($resultBytes)
}

function aesdecrypt {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline = $true, Mandatory = $true)]
        [string] $ciphertxt
    )
    $fullBytes = [Convert]::FromBase64String($ciphertxt)
    $aes = [System.Security.Cryptography.Aes]::Create()
    $aes.Key = $Global:ProfileConfig.cryptokey
    $ivLength = $aes.BlockSize / 8
    $aes.IV = [byte[]]$fullBytes[0..($ivLength - 1)]
    $decryptor = $aes.CreateDecryptor()
    $cipherBytes = $fullBytes[$ivLength..($fullBytes.Length - 1)]
    $plainBytes = $decryptor.TransformFinalBlock($cipherBytes, 0, $cipherBytes.Length)
    return [System.Text.Encoding]::UTF8.GetString($plainBytes)
}

function global:edithosts {
    $editor = $global:ProfileConfig.editor
    if ($IsWindows) {
        $cmd = "$editor $env:windir\System32\drivers\etc\hosts" 
        sudo pwsh -c $cmd
        return
    }
    & sudo $editor /etc/hosts
}
