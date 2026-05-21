$env:UV_INDEX = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"

function global:py {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $remains = @()
    )
    uv run python @remains
}

function global:pv {
    if (Test-Path "./.venv/Scripts/activate.ps1" -ErrorAction SilentlyContinue) {
        . "./.venv/Scripts/activate.ps1"
    }
}
