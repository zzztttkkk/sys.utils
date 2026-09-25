function script:gen {
	param(
		[int32] $size = 4
	)

	$vowels = @(
		'a','e','i','o','u'
	)

	$onsets = @(
		'', 'b','c','d','f','g','h','j','k','l','m','n',
		'p','r','s','t','v','w','y','z',
		'bl','br','ch','cl','cr','dr','fl','fr',
		'gl','gr','pl','pr','sc','sh','sk','sl',
		'sm','sn','sp','st','sw','th','tr','tw'
	)

	$codas = @(
		'', 'b','d','f','g','k','l','m','n','p','r','s',
		't','v','z',
		'ch','ck','ft','ld','lf','lk','lm','lp',
		'lt','mp','nd','ng','nk','nt','rd','rk',
		'rm','rn','rp','rt','sh','sk','sp','st',
		'th'
	)
	$result = ''
	while ($result.Length -lt $size) {
		$onset = Get-Random $onsets
		$vowel = Get-Random $vowels
		$coda = Get-Random $codas
		$syllable = $onset + $vowel + $coda
		$result += $syllable
	}
	return $result
}

function global:pn {
	param(
		[int32] $size = 4
	)

	while($true) {
		$name = gen $size
		Write-Host -NoNewline ("`r" + (" " * 40) + "`r")
		Write-Host -NoNewline "$($name)? [y/n] " -ForegroundColor Yellow
		$key = [Console]::ReadKey($true)
		switch ($key.Key) {
			([ConsoleKey]::Y) {
				Write-Host
				Set-Clipboard -Value $name
				return $name
			}
			([ConsoleKey]::N) { return $null }
			Default {}
		}
	}
}
