function global:llama {
    param(
        [string]$opkind = ""
    )

    if ([string]::IsNullOrEmpty($opkind)) {
        $opkind = gum filter up down
    }
    if ([string]::IsNullOrEmpty($opkind)) {
        return
    }

    $model = "$HOME/scoop/apps/llama.cpp-cu131/current/models/google_gemma-4-E4B-it-Q8_0.gguf"

    switch ($opkind) {
        "up" {
            Start-Process llama-server.exe -ArgumentList "--port 3600 -m $model -c 8192 -ngl 99" -WindowStyle Hidden
            return 
        }
        "down" { 
            fkill llama-server
            return 
        }
        Default {}
    }
}