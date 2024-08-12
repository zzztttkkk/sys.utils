#Include _jxon.ahk
#Include Notify.ahk

try {
    ___txt__ := FileRead(EnvGet("HOMEPATH") . "/.config/.ahk.json")
    CFG := Jxon_Load(&___txt__)
} catch {
}

clear_clipboard() {
    A_Clipboard := ""
}

pwd_to_clipboard(name) {
    pid := WinGetPID(name)
    pwds := CFG["passwords"]
    A_Clipboard := pwds[name]
    SetTimer(clear_clipboard, -3000)
    Notify.Show('Info', 'Password is on clipboard now, ' . name, , , , 'DUR=2')
}

#t::
{
    try {
        Run(CFG["terminal"])
    } catch {
    }
}


#!p::
{
    title := WinGetTitle("A")
    try
    {
        pwd_to_clipboard(title)
    }
    catch {
    }
}