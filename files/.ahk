#t::
{
    try {
        Run("pwsh -WD ~")
    } catch {
    }
}

^Space::
{
    Send "# {Space}"
    Send "{Backspace}"
}