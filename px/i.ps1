function script:install_pwsh {
    $target = ""
    if ($IsWindows) {
        $target = "$HOME/Documents/PowerShell"
    }
    else {
        $target = "$HOME/.config/powershell"
    }

    Remove-Item -Force $target/*.ps1 -ErrorAction SilentlyContinue
    Remove-Item -Force $target/*.psm1 -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $target/box -ErrorAction SilentlyContinue

    Copy-Item -Recurse  -Path ./pwsh/* -Destination $target -Force
}

$dest_flag = ""
if ($IsWindows) {
    $dest_flag = "<DEST:WIN>:"
}
elseif ($IsLinux) {
    $dest_flag = "<DEST:LINUX>:"
}
elseif ($IsMacOS) {
    $dest_flag = "<DEST:MAC>:"
}
$common_dest_flag = "<DEST:ALL>:"

function script:cut_dest([string] $v) {
    $idx = $v.IndexOf($common_dest_flag)
    if ( $idx -lt 0) {
        $idx = $v.IndexOf($dest_flag)
        if ( $idx -lt 0) { return $null; }
        return $v.Substring($idx + $dest_flag.Length).Trim();
    }
    return $v.Substring($idx + $common_dest_flag.Length).Trim();
}

function script:install_files {
    $items = Get-ChildItem -Path ./files -File
    foreach ($item in $items) {
        $lines = @(Get-Content $item.FullName -Head 6)
        if ($lines.Count -lt 1) { continue; }
        $dest = ""
        foreach ($line in $lines) {
            $dest = cut_dest $line;
            if ([string]::IsNullOrEmpty($dest)) { continue; }
            break;
        }
        if ([string]::IsNullOrEmpty($dest)) { continue; }
        $dest = $ExecutionContext.InvokeCommand.ExpandString($dest)
        $dest = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath($dest)
        if (-not $dest.StartsWith($HOME + [System.IO.Path]::DirectorySeparatorChar)) { continue; }

        $dir = Split-Path $dest -Parent
        New-Item -ItemType Directory -Force $dir | Out-Null
        Copy-Item -Path $item.FullName -Destination $dest -Force
        Write-Host "Install: ${dest}" -ForegroundColor Cyan 
    }
}

install_pwsh
install_files

if (-not(Test-Path ~/.pwsh.profile.toml)) {
    Copy-Item $PSScriptRoot/default.profile.toml ~/.pwsh.profile.toml
}