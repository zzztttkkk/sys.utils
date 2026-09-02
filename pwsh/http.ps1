function global:http {
    param (
        [string]$url = $null,

        [Alias("m")]
        [string]$method = $null,

        [Alias("q")]
        [string[]]$query = $null,

        [Alias("h")]
        [string[]]$headers = $null,

        [Alias("o")]
        [string]$output = $null,

        [int32]$timeout = 30
    )

    # URL
    if ([string]::IsNullOrWhiteSpace($url)) {
        $url = Read-Host "Enter URL"
    }

    if ([string]::IsNullOrWhiteSpace($url)) {
        Write-Host "URL is empty, please enter a valid URL." -ForegroundColor Yellow
        return
    }

    # Method
    if ([string]::IsNullOrWhiteSpace($method)) {
        $method = gum choose GET POST PUT HEAD DELETE OPTIONS PATCH
    }

    if ([string]::IsNullOrWhiteSpace($method)) {
        Write-Host "Method is empty, please select a valid method." -ForegroundColor Yellow
        return
    }

    $method = $method.ToUpperInvariant()

    function add {
        param (
            [hashtable] $dest,
            [string]$key,
            [string]$value
        )
        $prev = $dest[$key]
        if ($null -eq $prev) {
            $dest[$key] = @($value);
            return;
        }
        $prev += $value;
        $dest[$key] = $prev;
    }

    # Query
    $queryParams = @{}
    if ($null -ne $query) {
        if (($query.Count -eq 1) -and ($query[0] -eq "?")) {
            if (confirm "Should add query?" "No") {
                while ($true) {
                    $key = Read-Host "Enter query key, empty to exit"

                    if ([string]::IsNullOrWhiteSpace($key)) {
                        break
                    }

                    $value = Read-Host "Enter query value"
                    add $queryParams $key $value
                }
            }
        }
        else {
            foreach ($item in $query) {
                $key, $value = $item -split "=", 2
                add $queryParams $key $value
            }
        }
    }

    # Header
    $headersParams = @{}
    if ($null -ne $headers) {
        if (($headers.Count -eq 1) -and ($headers[0] -eq "?")) {
            if (confirm "Should add header?" "No") {
                while ($true) {
                    $key = Read-Host "Enter header key, empty to exit"
                    if ([string]::IsNullOrWhiteSpace($key)) {
                        break
                    }
                    $value = Read-Host "Enter header value"
                    $headersParams[$key] = $value
                }
            }
        }
        else {
            foreach ($item in $headers) {
                $key, $value = $item -split "=", 2
                $headersParams[$key] = $value
            }
        }
    }

    # Body
    $body = $null

    if ($method -notin @("GET", "HEAD", "OPTIONS")) {
        if (confirm "Should use body?") {
            $kind = gum choose text file json

            switch ($kind) {
                "text" {
                    $body = gum write -prompt "Enter body text"

                    if ([string]::IsNullOrWhiteSpace($body)) {
                        Write-Host "Body is empty." -ForegroundColor Yellow
                    }
                }
                "file" {
                    $file = gum file
                    if ([string]::IsNullOrWhiteSpace($file)) {
                        Write-Host "No file selected." -ForegroundColor Yellow
                        return
                    }

                    if (-not (Test-Path -LiteralPath $file -PathType Leaf)) {
                        Write-Host "File does not exist: $file" -ForegroundColor Red
                        return
                    }

                    $body = Get-Content -LiteralPath $file -Raw
                }
                "json" {
                    $uuid = New-Guid
                    $tmp = [System.IO.Path]::GetTempPath()
                    $editor = $Global:ProfileConfig.editor
                    $tmpfile = Join-Path $tmp "$($uuid).json"
                    try {
                        & $editor $tmpfile
                        $body = Get-Content -LiteralPath $tmpfile -Raw -ErrorAction SilentlyContinue
                    }
                    finally {
                        Remove-Item -LiteralPath $tmpfile -Force -ErrorAction SilentlyContinue
                    }
                    if ([string]::IsNullOrEmpty($body)) {
                        Write-Host "Body is empty." -ForegroundColor Yellow
                        return
                    }
                    $headersParams["Content-Type"] = "application/json"
                }
                Default {
                }
            }
        }
    }

    # Build query string
    if ($queryParams.Count -gt 0) {
        $builder = [System.UriBuilder]$url
        $existingQuery = $builder.Query.TrimStart('?')

        $newQuery = @();
        $queryParams.GetEnumerator() | ForEach-Object {
            $key = [System.Uri]::EscapeDataString([string]$_.Key);
            $vs = $_.Value;
            foreach ($v in $vs) {
                $newQuery += "{0}={1}" -f $key, [System.Uri]::EscapeDataString($v)
            }
        }

        if ([string]::IsNullOrWhiteSpace($existingQuery)) {
            $builder.Query = $newQuery -join "&"
        }
        else {
            $builder.Query = "$existingQuery&$($newQuery -join '&')"
        }

        $url = $builder.Uri.AbsoluteUri
    }

    # Request options
    $params = @{
        Uri                     = $url
        Method                  = $method
        Headers                 = $headersParams
        ErrorAction             = "Stop"
        OperationTimeoutSeconds = $timeout
    }

    if ($null -ne $body) {
        $params.Body = $body
    }

    # Request
    try {
        $response = Invoke-WebRequest @params

        Write-Host ""
        Write-Host "HTTP $($response.StatusCode) $($response.StatusDescription)" -ForegroundColor Green

        Write-Host ""
        Write-Host "Response Headers:" -ForegroundColor DarkGray

        foreach ($header in $response.Headers.GetEnumerator()) {
            Write-Host "$($header.Key): $($header.Value)"
        }

        if ([string]::IsNullOrEmpty($output)) {
            Write-Host ""
            Write-Host "Response Body:" -ForegroundColor DarkGray

            if ([string]::IsNullOrEmpty($response.Content)) {
                Write-Host "(empty)"
            }
            else {
                Write-Output $response.Content
            }
        }
        else {
            $stream = $response.RawContentStream
            $file = [System.IO.File]::Create($output)
            try {
                $stream.CopyTo($file)
            }
            finally {
                $file.Dispose()
            }
        }
    }
    catch {
        $exception = $_.Exception

        Write-Host ""
        Write-Host "Request failed:" -ForegroundColor Red
        Write-Host $exception.Message -ForegroundColor Red

        if ($exception.Response) {
            try {
                $response = $exception.Response

                Write-Host ""
                Write-Host "HTTP $([int]$response.StatusCode) $($response.StatusDescription)" -ForegroundColor Red

                $stream = $response.GetResponseStream()

                if ($stream) {
                    $reader = [System.IO.StreamReader]::new($stream)

                    try {
                        $content = $reader.ReadToEnd()

                        if (-not [string]::IsNullOrEmpty($content)) {
                            Write-Host ""
                            Write-Host "Response Body:" -ForegroundColor DarkGray
                            Write-Output $content
                        }
                    }
                    finally {
                        $reader.Dispose()
                    }
                }
            }
            catch {
                # Ignore secondary response parsing errors.
            }
        }
    }
}