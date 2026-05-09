$ENV:PATH += ":$HOME/.local/bin:$HOME/bin"

Set-Alias -Name ls -Value Get-ChildItem

function ll {
    Get-ChildItem -Force    
}
