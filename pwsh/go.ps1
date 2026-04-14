function global:gouv() {
    param(
        [string]$root = $PWD,
        [int]$depth = 3,
        [Alias("s")]
        [switch]$sync = $false
    )

    $version = $(go env GOVERSION).Substring(2).Trim()

    $items = Get-ChildItem -Path $root -Recurse -File  -Include @("go.mod", "go.work") -Depth $depth
    if ($items.Count -eq 0) {
        Write-Output "no go.mod or go.work found"
        return
    }

    $works = @()

    Write-Output "gouv version: $version"
    foreach ($file in $items) {
        if ($file.FullName -match "[/\\]vendor[/\\]") {
            continue
        }
        $dir = Split-Path -Path $file.FullName -Parent
        Push-Location $dir
        try {
            if ($file.Name -eq "go.mod") {
  
                go mod edit -go $version
                Write-Output "update mod: $dir"
                if ($sync) {
                    go mod tidy
                    Write-Output "tidy mod: $dir"
                }
            }
            else {
                $works += $dir
                go work edit -go $version
                Write-Output "update work: $dir"
            }
        }
        finally {
            Pop-Location
        }
    }

    if ($sync) {
        foreach ($work in $works) {
            Write-Output "sync work: $work"
            Push-Location $work
            go work sync
            Pop-Location
        }
    }

    Write-Output "done"
}
