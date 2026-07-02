function global:llmctx {
    param (
        [string] $root = ".",
        [alias("g")]
        [string] $glob = "*.*",
        [alias("o")]
        [switch] $output = $false,
        [alias("e")]
        [string[]] $exclude = @(),
        [alias("q")]
        [switch] $quiet = $false,
        [alias("r")]
        [switch] $recursive = $false
    )
    if ($output) {
        $quiet = $true
    }

    $exclude += "*_string.go"

    $ingit = $true;
    git rev-parse --is-inside-work-tree 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $ingit = $false;
    }

    $root = [IO.Path]::GetFullPath((Resolve-Path $root).Path).TrimEnd([IO.Path]::DirectorySeparatorChar)

    $codes = @()
    if ($ingit) {
        $repo_root = git rev-parse --show-toplevel
        $codes = @(git ls-files --cached --others --exclude-standard) | ForEach-Object {
            if (-not ($_ -like $glob)) { return $null }

            $fp = Join-Path $repo_root $_
            $dir = Split-Path $fp -Parent
            $dir = [IO.Path]::GetFullPath($dir).TrimEnd([IO.Path]::DirectorySeparatorChar)
            if ($recursive) {
                if (-not $dir.StartsWith($root)) {
                    return $null
                }
            }
            else {
                if ($dir -ne $root) {
                    return $null
                }
            }
            return $fp
        }
    }
    else {
        $gcargs = @{
            Path    = $root
            File    = $true
            Filter  = $glob
            Recurse = $recursive
        }
        $codes = @(Get-ChildItem @gcargs | Select-Object -ExpandProperty FullName)
    }
    if ($codes.Count -eq 0) {
        Write-Host "empty codes: $glob" -ForegroundColor Yellow
        return
    }

    $count = 0
    $tmp = foreach ($code in $codes) {
        if ([string]::IsNullOrEmpty($code)) { continue; }

        $exed = $exclude | Where-Object { 
            $code -like $_ 
        }
        if ($exed) { continue; }

        $rc = Get-Content -Path $code -Encoding UTF8 -Raw
        $count += $rc.Length
        $code = $code.Substring($root.Length)
        "--- $code"
        $rc
        ""
        if (!$quiet) {
            Write-Host "JOIN $code; size: $($rc.Length)" -ForegroundColor Cyan
        }
    }

    $result = $tmp -join "`n"
    if ($output) { Write-Output $result }
    else { Set-Clipboard -Value $result }

    if (!$quiet) {
        Write-Host "Total size: $count chars; Estimated tokens: $([math]::Round($count / 3.5))" -ForegroundColor Cyan
    }
}