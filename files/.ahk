#Include _jxon.ahk

try {
    _pwdstxt := FileRead(EnvGet("HOMEPATH") . "/.config/.ahkpwds.json")
    pwds := Jxon_Load(&_pwdstxt)
} catch {
}

clear_clipboard() {
    A_Clipboard := ""
}

pwd_to_clipboard(name) {
    pid := WinGetPID(name)
    A_Clipboard := pwds[name]
    SetTimer(clear_clipboard, -3000)
}


#t::
{
    Run("pwsh -WorkingDirectory ~")
}


#!p::
{
    for name in ["Warframe"]
        try
        {
            pwd_to_clipboard(name)
            break
        }
        catch
        { }
}