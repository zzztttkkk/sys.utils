class _ProfileConfig {
    [string]$proxy;
    [string]$editor;
    [string]$vscroot;

    [hashtable]$fexpbookmarkets; # string -> string
    [hashtable]$gitauths; # string -> string
    [hashtable]$sshauths; # string -> string
    [hashtable]$sshports; # string -> int

    _ProfileConfig() {
        $this.proxy = "";
        $this.editor = "";
        $this.vscroot = "";

        $this.fexpbookmarkets = @{};
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

            if ($null -ne $raw.proxy) { $this.proxy = $raw.proxy }
            if ($null -ne $raw.editor) { $this.editor = $raw.editor }

            if ($null -ne $raw.git.auths) {
                $this.gitauths = $raw.git.auths
            }
            if ($null -ne $raw.ssh.auths) {
                $this.sshauths = $raw.ssh.auths
            }
            if ($null -ne $raw.ssh.ports) {
                $this.sshports = $raw.ssh.ports
            }
            if ($null -ne $raw.fexp.bookmarkets) {
                $this.fexpbookmarkets = $raw.fexp.bookmarkets
            }
        }
        catch {
            Write-Warning "Load failed: $($_.Exception.Message)"
        }
    }
}

$Global:ProfileConfig = [_ProfileConfig]::new()

Export-ModuleMember -Variable ProfileConfig
