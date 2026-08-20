function script:list {
    param (
        [string] $p
    )
    $items = Get-ChildItem -Directory $p | Select-Object -ExpandProperty name | Where-Object { -not $_.StartsWith(".") }
    return $items
}

function script:choose() {
    param (
        [String] $root
    )
    $items = @(list $root)
    $exclude = $null
    if (Test-Path "$root/.vsc.json") {
        $raw = Get-Content "$root/.vsc.json" -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction SilentlyContinue
        $exclude = $raw.exclude
        if (($null -ne $raw) -and ($null -ne $raw.expands)) {
            @($raw.expands) | ForEach-Object {
                if (-not (Test-Path "$root/$_")) { 
                    Write-Host "$_ is not exists" -ForegroundColor Yellow
                    return; 
                }
                $prefix = $_
                $subitems = list "$root/$_" | ForEach-Object { "$prefix/$_" }
                $items += $subitems
            }
        }
    }
    if ($items.Count -eq 0) { return }

    if ($null -ne $exclude) {
        $items = $items | Where-Object { -not $_.StartsWith($exclude) }
    }

    if ($items.Count -eq 0) { return }

    if ($items.Count -eq 1) {
        $name = $items
    }
    else {
        $items = $items | Sort-Object
        $name = gum filter $items
    }

    if ( [string]::IsNullOrEmpty($name) ) {
        return
    }

    $editor = "code"
    if (Test-Path "$root/$name/.editor") {
        $editor = (Get-Content "$root/$name/.editor" -TotalCount 1).Trim()
    }
    Start-Process -FilePath $editor -ArgumentList "$root/$name" -WindowStyle Hidden
}

function vsc() {
    param (
        [alias("w")]
        [switch] $work
    )

    $root = "";
    if ($work) {
        $root = $global:ProfileConfig.vscwroot;
    }
    else {
        $root = $global:ProfileConfig.vscroot;
    }

    if ([string]::IsNullOrEmpty($root)) {
        Write-Error "empty root"
        return
    }
    $root = $ExecutionContext.InvokeCommand.ExpandString($root);
    $root = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($root)

    choose $root
}
