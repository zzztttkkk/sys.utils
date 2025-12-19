$global:envfilekeys = @()

function LoadEnvFile {
    param (
        [string]$Path = ".env"
    )
    
    if (Test-Path $Path) {
        Get-Content $Path | ForEach-Object {
            $line = $_.Trim()
            if ([string]::IsNullOrEmpty($line) -or $line.StartsWith("#")) {
                continue
            }

            $idx = $line.IndexOf("=")
            if ($idx -lt 0) {
                continue
            }
            $name = $line.Substring(0, $idx).Trim()
            if (-not $name -match '^[a-zA-Z_][a-zA-Z0-9_]*$') {
                Write-Error "Invalid name: $name, in file $Path"
                continue
            }
            $value = $line.Substring($idx + 1).Trim()
            [Environment]::SetEnvironmentVariable($name, $value)

            $global:envfilekeys += $name
        }
    }
    else {
        Write-Error "File not found: $Path"
    }
}


function ClearEnvFileKeys {
    foreach ($key in $global:envfilekeys) {
        [Environment]::SetEnvironmentVariable($key, $null)
    }
    $global:envfilekeys = @()
}