class _ProfileConfig {
    [string]$proxy;
    [string]$editor;
    [string]$vscroot;
    [string]$vscwroot;

    $fexp; 
    $git; 
    $ssh;
    $s3;
    $feats;

    [void]load() {
        $file = "$global:HOME/.pwsh.profile.json";
        if (-not(Test-Path $file -ErrorAction SilentlyContinue)) {
            return;
        }

        try {
            $raw = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop -AsHashtable

            foreach ($prop in @(
                    'proxy', 'editor', 'vscroot', 'vscwroot',
                    'fexp', 'git', 'ssh', 's3', 'feats'
                )) {
                if ($null -ne $raw.$prop) { $this.$prop = $raw.$prop }
            }
        }
        catch {
            Write-Warning "Load failed: $($_.Exception.Message)"
        }
    }
}

$Global:ProfileConfig = [_ProfileConfig]::new()

Export-ModuleMember -Variable ProfileConfig
