function Read-Env {
    param (
        [string]$path = ".env"
    )
    
    if (-not (Test-Path $path)) {
        Write-Error "File not found: $path"
        return
    }

    Get-Content $path | ForEach-Object {
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
            Write-Error "Invalid env name: $name, in file $path"
            return
        }

        $value = $line.Substring($idx + 1).Trim()
        if ($value.StartsWith('"') -and $value.EndsWith('"') -and $value.Length -ge 2) {
            $value = $value.Substring(1, $value.Length - 2)
        }

        [Environment]::SetEnvironmentVariable($name, $value)
        Write-Verbose "Set env $name = $value"
    }
}

if ($null -eq $script:EnvStack) {
    $script:EnvStack = [System.Collections.Generic.Stack[hashtable]]::new()
}

function Push-Env {
    param (
        [string]$path = ".env"
    )
    
    $snapshot = @{}
    Get-ChildItem -Path env: | ForEach-Object {
        $snapshot[$_.Name] = $_.Value
    }

    $script:EnvStack.Push($snapshot)
    Read-Env -path $path
}

function Pop-Env {
    if ($script:EnvStack.Count -eq 0) { return; }
    
    $snapshot = $script:EnvStack.Pop()

    $currentKeys = (Get-ChildItem -Path env:).Name
    foreach ($key in $currentKeys) {
        if (-not $snapshot.ContainsKey($key)) {
            Remove-Item -Path "env:\$key" -ErrorAction SilentlyContinue
        }
    }

    foreach ($entry in $snapshot.GetEnumerator()) {
        Set-Item -Path "env:\$($entry.Key)" -Value $entry.Value
    }
}

function envscope {
    param (
        [Parameter(Position = 0, Mandatory = $true)]
        [scriptblock]$command,
        [Parameter(Position = 1)]
        [string]$path = ".env"
    )

    Push-Env -path $path
    try {
        & $command
    }
    finally {
        Pop-Env
    }
}