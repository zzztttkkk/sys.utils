function global:py {
	param (
		[Parameter(ValueFromRemainingArguments = $true)]
		[string[]] $remains = @()
	)
	uv run python @remains
}

function global:pv {
	$candidates = @(
		"./.venv/Scripts/activate.ps1",
		"./.venv/bin/activate.ps1"
	)
	foreach ($candidate in $candidates) {
		if (Test-Path -LiteralPath $candidate -PathType Leaf) {
			. $candidate
			return
		}
	}
	Write-Host "no .venv found in $((Get-Location).Path)" -ForegroundColor Yellow
}
