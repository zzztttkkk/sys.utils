class _ProfileConfig {
    [string]$proxy;
    [string]$editor;
    [string]$vscroot;
    [string]$vscwroot;
    [string]$sshdefault;

    [hashtable]$fexpmarks; # string -> string
    [hashtable]$gitauths; # string -> string
    [hashtable]$sshauths; # string -> string
    [hashtable]$sshports; # string -> int
    [hashtable]$s3; # string -> object

    [void]load() {
        $file = "$global:HOME/.pwsh.profile.toml";
        if (-not(Test-Path $file -ErrorAction SilentlyContinue)) {
            return;
        }

        try {
            $raw = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Toml -ErrorAction Stop

            foreach ($prop in @('proxy', 'editor', 'vscroot', 'vscwroot', 'sshdefault')) {
                if ($null -ne $raw.$prop) { $this.$prop = $raw.$prop }
            }

            $this.gitauths = [hashtable]$raw.git.auths; 
            $this.sshauths = [hashtable]$raw.ssh.auths; 
            $this.sshports = [hashtable]$raw.ssh.ports; 
            $this.fexpmarks = [hashtable]$raw.fexp.marks; 
            $this.s3 = [hashtable]$raw.s3;
        }
        catch {
            Write-Warning "Load failed: $($_.Exception.Message)"
        }
    }
}

$Global:ProfileConfig = [_ProfileConfig]::new()

Export-ModuleMember -Variable ProfileConfig
