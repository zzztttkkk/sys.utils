function global:s3 {
    param(
        [Alias("b")]
        [string]$bucket = "",

        [Alias("a")]
        [string]$action = ""
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

    $key = Read-Host -Prompt "enter key" -MaskInput
    $ak = decrypt $bktcfg.ak -passwd $key
    if ([string]::IsNullOrEmpty($ak)) {
        Write-Host "No AK found" -ForegroundColor Yellow
        return
    }
    $sk = decrypt $bktcfg.sk -passwd $key
    if ([string]::IsNullOrEmpty($sk)) {
        Write-Host "No SK found" -ForegroundColor Yellow
        return
    }

    try {
        mc alias set this $bktcfg.endpoint $ak $sk

        switch ($action) {
            "list" {
                mc ls /this/$($bktcfg.name)
                return
            }
            "upload" {
                $files = Get-ChildItem -File -Path $wd | Select-Object -ExpandProperty FullName
                $file = gum filter $files
                if ([string]::IsNullOrEmpty($file)) {
                    Write-Host "No file selected" -ForegroundColor Yellow
                    return
                }
                $name = Split-Path $file -Leaf
                mc cp $file /this/$($bktcfg.name)/$name
                mc share download --expire 30m /this/$($bktcfg.name)/$name
                return
            }
            "download" {
                $file = Read-Host "Remote FileName"
                if ([string]::IsNullOrEmpty($file)) {
                    Write-Host "No file selected" -ForegroundColor Yellow
                    return
                }
                $target = Join-Path $HOME "Downloads/$file"
                mc cp /this/$($bktcfg.name)/$file $target
                return
            }
            "share" {
                $file = Read-Host "Remote FileName"
                if ([string]::IsNullOrEmpty($file)) {
                    Write-Host "No file selected" -ForegroundColor Yellow
                    return
                }
                mc share download --expire 30m /this/$($bktcfg.name)/$file
                return
            }
            default {
                Write-Host "Unknown action: $action" -ForegroundColor Yellow
                return
            }
        }
    }
    finally {
        mc alias rm this
    }
}