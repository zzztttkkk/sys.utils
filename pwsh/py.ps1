function global:pv {
    param (
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]] $remains = @()
    )

    if (Test-Path "./.venv" -ErrorAction SilentlyContinue) {
        . ./.venv/Scripts/Activate.ps1
    }
    if ($remains.Count -lt 1) { return; }
    python $remains
}