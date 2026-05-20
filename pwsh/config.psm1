class _ProfileConfig {
    [string]$proxy;
    [string]$editor;
    [string]$vscroot;
    [string]$sshdefault;

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

            if ($null -ne $raw.proxy) { $this.proxy = $raw.proxy }
            if ($null -ne $raw.editor) { $this.editor = $raw.editor }
            if ($null -ne $raw.vscroot) { $this.vscroot = $raw.vscroot }
            if ($null -ne $raw.sshdefault) { $this.sshdefault = $raw.sshdefault }

            if ($null -ne $raw.git.auths) {
                $this.gitauths = $raw.git.auths
            }
            if ($null -ne $raw.ssh.auths) {
                $this.sshauths = $raw.ssh.auths
            }
            if ($null -ne $raw.ssh.ports) {
                $this.sshports = $raw.ssh.ports
            }
            if ($null -ne $raw.fexp.marks) {
                $this.fexpmarks = $raw.fexp.marks
            }
        }
        catch {
            Write-Warning "Load failed: $($_.Exception.Message)"
        }
    }
}

$Global:ProfileConfig = [_ProfileConfig]::new()

Export-ModuleMember -Variable ProfileConfig
