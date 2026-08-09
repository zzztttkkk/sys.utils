function global:s3 {
    param(
        [Alias("b")]
        [string]$bucket = "",

        [Alias("a")]
        [string]$action = "",

        [Alias("f")]
        [string]$file = ""
    )

    $alls3 = $Global:ProfileConfig.s3
    if ($null -eq $alls3) {
        Write-Host "No S3 config found" -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrEmpty($bucket)) {
        $bucket = (gum filter $alls3.Keys).Trim()
    }
    $bktcfg = $alls3[$bucket]
    if ($null -eq $bktcfg) {
        Write-Host "No S3 config found for bucket: $bucket" -ForegroundColor Yellow
        return
    }

    if ([string]::IsNullOrEmpty($action)) {
        $action = (gum filter list upload download share).Trim()
    }

    if ([string]::IsNullOrEmpty($action)) {
        Write-Host "No action selected" -ForegroundColor Yellow
        return
    }

    $endpoint = $bktcfg.endpoint
    $idx = $endpoint.IndexOf("://")
    if ($idx -lt 0) {
        Write-Host "Invalid endpoint: $endpoint" -ForegroundColor Yellow
        return
    }
    $schema = $endpoint.Substring(0, $idx + 3)
    $endpoint = $endpoint.Substring($idx + 3)

    $env:MC_HOST_tmp = "$($schema)$($bktcfg.ak):$($bktcfg.sk)@$($endpoint)"
    try {
        switch ($action) {
            "list" {
                mc ls /tmp/$($bktcfg.name)
                return
            }
            "upload" {
                if ([string]::IsNullOrEmpty($file)) {
                    Write-Host "No file selected" -ForegroundColor Yellow
                    return
                }
                $name = Split-Path $file -Leaf
                mc cp $file /tmp/$($bktcfg.name)/$name
                return
            }
            "download" {
                if ([string]::IsNullOrEmpty($file)) {
                    Write-Host  "No file selected" -ForegroundColor Yellow
                    return
                }
                $name = Split-Path $file -Leaf
                $target = Join-Path $HOME "Downloads/$name"
                mc cp /tmp/$($bktcfg.name)/$file $target
                return
            }
            "share" {
                if ([string]::IsNullOrEmpty($file)) {
                    Write-Host "No file selected" -ForegroundColor Yellow
                    return
                }
                mc share download --expire 30m /tmp/$($bktcfg.name)/$file
                return
            }
            default {
                Write-Host "Unknown action: $action" -ForegroundColor Yellow
                return
            }
        }
    }
    finally {
        $env:MC_HOST_tmp = $null
    }
}