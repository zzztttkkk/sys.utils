$script:_props = @(
    'proxy', 'editor', 'vscroot', 'vscwroot',
    'fexp', 'git', 'ssh', 's3', 'feats'
);

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
        try {
            $file = "$global:HOME/.pwsh.profile.json";
            if (-not(Test-Path $file -ErrorAction SilentlyContinue)) {
                return;
            }
            $raw = Get-Content $file -Raw -Encoding UTF8 | ConvertFrom-Json -ErrorAction Stop -AsHashtable

            foreach ($prop in $script:_props) {
                if ($null -ne $raw.$prop) { $this.$prop = $raw.$prop }
            }
        }
        catch {
            Write-Warning "Load failed: $($_.Exception.Message)"
        }
        finally {
            if ([string]::IsNullOrEmpty($this.editor)) {
                foreach ($cmd in @("hx", "vim", "vi")) {
                    if (Get-Command $cmd -ErrorAction SilentlyContinue) {
                        $this.editor = $cmd;
                        break;
                    }
                }
            }
        }
    }

    [void] save() {
        try {
            $file = "$global:HOME/.pwsh.profile.json"
            $data = @{}
            foreach ($prop in $script:_props) {
                if ($null -ne $this.$prop) {
                    $data[$prop] = $this.$prop
                }
            }
            $json = $data | ConvertTo-Json -Depth 5 -Compress:$false
            [System.IO.File]::WriteAllText($file, $json, [System.Text.UTF8Encoding]::new($false))
        }
        catch {
            Write-Warning "Save failed: $($_.Exception.Message)"
        }
    }

    [void] fexpmarkdel() {
        $this.fexpmarkdel($null);
    }

    [void] fexpmarkdel([string] $key) {
        $marks = $this.fexp.marks;
        if ($null -eq $marks) { return; }
        if ([string]::IsNullOrEmpty($key)) {
            $key = gum filter $marks.Keys
        }
        if ([string]::IsNullOrEmpty($key)) { return; }

        $marks.Remove($key);

        $this.save();
    }

    [void] fexpmarkadd([string] $key) {
        $this.fexpmarkadd($key, ".", $false)
    }

    [void] fexpmarkadd([string] $key, [bool] $update) {
        $this.fexpmarkadd($key, ".", $update)
    }

    [void] fexpmarkadd([string] $key, [string] $target) {
        $this.fexpmarkadd($key, $target, $false)
    }

    [void] fexpmarkadd([string] $key, [string] $target, [bool] $update) {
        if ([string]::IsNullOrEmpty($key)) {
            Write-Warning "key is empty"
            return;
        }
        if ([string]::IsNullOrEmpty($target)) {
            Write-Warning "target is empty"
            return;
        }
        if ($target -eq ".") {
            $target = (Get-Location).Path
        }

        if ($null -eq $this.fexp) {
            $this.fexp = @{ marks = @{} }
        }
        elseif ($null -eq $this.fexp.marks) {
            $this.fexp.marks = @{}
        }

        $prev = $this.fexp.marks[$key]
        if (-not [string]::IsNullOrEmpty($prev)) {
            if (-not $update) {
                Write-Warning "mark $key already exists"
                return;
            }
        }

        $this.fexp.marks[$key] = $target

        $this.save()
    }

    [void] sshcadd([string] $name, [string] $auth) {
        $this.sshcadd($name, $auth, 0, $false)
    }

    [void] sshcadd([string] $name, [string] $auth, [int] $port) {
        $this.sshcadd($name, $auth, $port, $false)
    }

    [void] sshcadd([string] $name, [string] $auth, [bool] $update) {
        $this.sshcadd($name, $auth, 0, $update)
    }

    [void] sshcadd([string] $name, [string] $auth, [int] $port, [bool] $update) {
        if ([string]::IsNullOrEmpty($name)) {
            Write-Warning "name is empty"
            return;
        }
        if ([string]::IsNullOrEmpty($auth)) {
            Write-Warning "auth is empty"
            return;
        }

        if ($null -eq $this.ssh) {
            $this.ssh = @{ auths = @{}; ports = @{} }
        }
        if ($null -eq $this.ssh.auths) {
            $this.ssh.auths = @{}
        }
        if ($null -eq $this.ssh.ports) {
            $this.ssh.ports = @{}
        }

        $prev = $this.ssh.auths[$name]
        if (-not [string]::IsNullOrEmpty($prev)) {
            if (-not $update) {
                Write-Warning "ssh $name already exists"
                return;
            }
        }

        $this.ssh.auths[$name] = $auth
        if ($port -gt 0) {
            $this.ssh.ports[$name] = $port
        }
        else {
            $this.ssh.ports.Remove($name);
        }

        $this.save()
    }

    [void] sshcdel() {
        $this.sshcdel($null);
    }

    [void] sshcdel([string] $name) {
        $auths = $this.ssh.auths;
        if ($null -eq $auths) { return; }
        if ([string]::IsNullOrEmpty($name)) {
            $name = gum filter $auths.Keys
        }
        if ([string]::IsNullOrEmpty($name)) { return; }

        $auths.Remove($name);
        if ($null -ne $this.ssh.ports) {
            $this.ssh.ports.Remove($name);
        }

        $this.save();
    }
}

$Global:ProfileConfig = [_ProfileConfig]::new();

Export-ModuleMember -Variable ProfileConfig
