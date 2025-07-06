$ENV:PATH = "$HOME/.local/bin:$HOME/bin:" + $ENV:PATH 

function ll {
    Get-ChildItem -Force    
}