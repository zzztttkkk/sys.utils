$ENV:PATH = "$HOME/.local/bin:$HOME/bin:" + $ENV:PATH 

Set-Alias -Name ls -Value Get-ChildItem
function ll {
    Get-ChildItem -Force    
}
