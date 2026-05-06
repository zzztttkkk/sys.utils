function global:llmd {
    param (
        [Int16] $port = 3600
    )
    $root = "$HOME/scoop/apps/llama.cpp-cu131/current/models"
    $models = Get-ChildItem -Path $root -Filter *.gguf | Select-Object -ExpandProperty Name
    $model = gum filter $models
    if ([string]::IsNullOrEmpty($model)) {
        return;
    }
    llama-server.exe --port $port -m $root/$model -c 8192 -ngl 99
}

function global:llmctx {
    param (
        [string] $root = ".",
        [string] $glob = "*.*",
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
        if ($ingit) {
            git check-ignore -q -- $code 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                continue;
            }
        }
        if ($code.EndsWith("_string.go")) {
            continue;
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