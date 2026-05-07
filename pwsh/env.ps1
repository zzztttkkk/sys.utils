$script:envfilekeys = [System.Collections.Generic.HashSet[string]]::new()

function loadenv {
    param (
        [string]$Path = ".env"
    )
    
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            $line = $_.Trim()
            if ([string]::IsNullOrEmpty($line) -or $line.StartsWith("#")) {
                return
            }

            $idx = $line.IndexOf("=")
            if ($idx -lt 0) {
                return
            }
            $name = $line.Substring(0, $idx).Trim()
            if (-not ($name -match '^[a-zA-Z_][a-zA-Z0-9_]*$')) {
                Write-Error "Invalid env name: $name, in file $Path"
                return
            }
            $value = $line.Substring($idx + 1).Trim()
            if ($value.StartsWith("`"") -and $value.EndsWith("`"")) {
                $value = $value.Substring(1, $value.Length - 2)
            }
            [Environment]::SetEnvironmentVariable($name, $value)
            $envfilekeys.Add($name) | Out-Null
            Write-Output "Set env $name = $value"
        }
    }
    else {
        Write-Error "File not found: $Path"
    }
}

function clrenv {
    foreach ($key in $envfilekeys) {
        [Environment]::SetEnvironmentVariable($key, $null)
    }
    $envfilekeys.Clear()
}
