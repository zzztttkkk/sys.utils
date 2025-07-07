$ENV:PATH = "$HOME/.local/bin:$HOME/bin:" + $ENV:PATH 

Set-Alias ls = Get-ChildItem
function ll {
    Get-ChildItem -Force    
}
