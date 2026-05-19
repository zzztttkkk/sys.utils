$env:UV_INDEX = "https://mirrors.tuna.tsinghua.edu.cn/pypi/web/simple"

function global:py {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $remains = @()
    )
    uv run python @remains
}