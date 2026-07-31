class _ProfileConfig {
    [string]$proxy;
    [string]$editor;
    [string]$vscroot;
    [string]$vscwroot;
    [string]$sshdefault;
    [byte[]]$cryptokey;

    [hashtable]$fexpmarks; # string -> string
    [hashtable]$gitauths; # string -> string
    [hashtable]$sshauths; # string -> string
    [hashtable]$sshports; # string -> int

    _ProfileConfig() {
        $this.proxy = "";
        $this.editor = "";
        $this.vscroot = "";
        $this.sshdefault = "";

        $this.fexpmarks = @{};
        $this.gitauths = @{};
        $this.sshauths = @{};
        $this.sshports = @{};

        $editors = @("hx", "vim", "vi", "nano")
        foreach ($e in $editors) {
            if (Get-Command $e -ErrorAction SilentlyContinue) {
                $this.editor = $e
                break
            }
        }
    }

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

            if ($null -ne $raw.crypto.key) { 
                $this.cryptokey = [System.Text.Encoding]::UTF8.GetBytes($raw.crypto.key) 
            }

            if ($null -ne $raw.git.auths) { $this.gitauths = [hashtable]$raw.git.auths }
            if ($null -ne $raw.ssh.auths) { $this.sshauths = [hashtable]$raw.ssh.auths }
            if ($null -ne $raw.ssh.ports) { $this.sshports = [hashtable]$raw.ssh.ports }
            if ($null -ne $raw.fexp.marks) { $this.fexpmarks = [hashtable]$raw.fexp.marks }
        }
        catch {
            Write-Warning "Load failed: $($_.Exception.Message)"
        }
    }
}

$Global:ProfileConfig = [_ProfileConfig]::new()

Export-ModuleMember -Variable ProfileConfig
