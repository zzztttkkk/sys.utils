; <DEST:WIN>: $env:APPDATA/Microsoft/Windows/Start Menu/Programs/Startup/index.ahk

#Requires AutoHotkey v2.0
#SingleInstance Force

#t::
{
    try {
        Run("pwsh -WD ~")
    } catch {
    }
}

#+t::
{
    try {
        Run("sudo pwsh -WD ~")
    } catch {
    }
}