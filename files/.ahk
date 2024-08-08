#Include _jxon.ahk

try {
    _datatxt := FileRead(EnvGet("HOMEPATH") . "/.config/.ahk.json")
    data := Jxon_Load(&_datatxt)
} catch {
}

clear_clipboard() {
    A_Clipboard := ""
}

pwd_to_clipboard(name) {
    pid := WinGetPID(name)
    pwds := data["passwords"]
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