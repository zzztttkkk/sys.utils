function global:gouv() {
    param(
        [string]$root = $PWD,
        [int]$depth = 3
    )

    $version = $(go env GOVERSION).Substring(2).Trim()

    $items = Get-ChildItem -Path $root -Recurse -File  -Include @("go.mod", "go.work") -Depth $depth
    if ($items.Count -eq 0) {
        Write-Output "no go.mod or go.work found"
        return
    }

    Write-Output "gouv version: $version"
    foreach ($file in $items) {
        $dir = Split-Path -Path $file.FullName -Parent
        Push-Location $dir
        if ($file.Name -eq "go.mod") {
            go mod edit -go $version
            Write-Output "    update mod: $dir"
        }
        else {
            go work edit -go $version
            Write-Output "    update work: $dir"
        }
        Pop-Location
    }
    Write-Output "done"
}
