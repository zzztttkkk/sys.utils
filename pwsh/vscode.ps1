function vsc() {
    if ([string]::IsNullOrEmpty($global:ProfileConfig.vscroot)) {
        Write-Error "empty VscRoot"
        return
    }

    function list {
        param (
            [string] $p
        )
        $items = Get-ChildItem -Directory $p | Select-Object -ExpandProperty name | Where-Object { -not $_.StartsWith(".") }
        return $items
    }

    function __vscodechoose() {
        param (
            [String] $root
        )
        $items = @(list $root)
        if (Test-Path "$root/.vsc.toml") {
            $raw = Get-Content "$root/.vsc.toml" -Raw -Encoding UTF8 | ConvertFrom-Toml -ErrorAction SilentlyContinue
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

        Start-Process -FilePath code -ArgumentList "$root/$name" -WindowStyle Hidden
    }

    __vscodechoose $global:ProfileConfig.vscroot
}
