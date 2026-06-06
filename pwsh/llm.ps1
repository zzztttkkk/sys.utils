function global:llmctx {
    param (
        [string] $root = ".",
        [alias("g")]
        [string] $glob = "*.*",
        [alias("e")]
        [string[]] $exclude = @(),
        [alias("q")]
        [switch] $quiet = $false,
        [alias("r")]
        [switch] $recursive = $false
    )
    $ingit = $true;
    git rev-parse --is-inside-work-tree 2>&1 | Out-Null
    if ($LASTEXITCODE -ne 0) {
        $ingit = $false;
    }

    $exclude += "*_string.go"

    $root = (Resolve-Path $root).Path
    $gcargs = @{
        Path    = $root
        File    = $true
        Filter  = $glob
        Recurse = $recursive
    }
    $codes = @(Get-ChildItem @gcargs | Select-Object -ExpandProperty FullName)
    if ($codes.Count -eq 0) {
        Write-Host "empty codes: $glob" -ForegroundColor Yellow
        return
    }

    $count = 0
    $tmp = foreach ($code in $codes) {
        $exed = $exclude | Where-Object { 
            $code -like $_ 
        }
        if ($exed) { continue; }

        if ($ingit) {
            # TODO use `git ls-files --cached --others --exclude-standard` cache all git files in a hashset
            git check-ignore -q -- $code 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                continue;
            }
        }

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
    $tmp -join "`n" | Set-Clipboard
    if (!$quiet) {
        Write-Host "Total size: $count chars; Estimated tokens: $([math]::Round($count / 3.5))" -ForegroundColor Cyan
    }
}