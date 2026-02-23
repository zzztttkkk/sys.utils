$ENV:PATH = "$HOME/.local/bin:$HOME/bin:" + $ENV:PATH 

Set-Alias -Name ls -Value Get-ChildItem

function ll {
    Get-ChildItem -Force    
}

$global:__os_update_days = 7

function scrript:dnf_upos() {
    $lastinfo = dnf history list | grep -i -E 'upgrade|update' | head -n 1
    if (-not [string]::IsNullOrEmpty($lastinfo)) {
        $lastat = $lastinfo | awk '{print $4, $5}'
        $lastunix = Get-Date -Date $lastat -UFormat %s
        $nowunix = Get-Date -UFormat %s
        $days = ($nowunix - $lastunix) / (60 * 60 * 24)
        if (($days -lt $global:__os_update_days) -or ($days -eq $global:__os_update_days)) {
            Write-Host "Last update: $lastat (less than $global:__os_update_days days)"
            return
        }
    }
    dnf upgrade -y
}

function upos() {
    if (Get-Command dnf -ErrorAction SilentlyContinue) {
        dnf_upos
    }
}
