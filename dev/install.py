import sys
import os
import pathlib
import shutil


def pwsh():
    dp = ""
    match sys.platform:
        case "win32":
            dp = os.path.join(pathlib.Path.home(), "Documents/PowerShell")
        case "linux":
            dp = os.path.join(pathlib.Path.home(), ".config/powershell")
        case _:
            return

    if not os.path.exists(dp):
        os.makedirs(dp)

    shutil.copytree("./pwsh", dp, dirs_exist_ok=True)


def ahk():
    if sys.platform != "win32":
        return

    for name in [".ahk", "_jxon.ahk", "Notify.ahk"]:
        dist = f"{os.path.expanduser('~')}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/{name}"
        if os.path.exists(dist):
            os.remove(dist)
        shutil.copyfile(
            os.path.join(os.path.dirname(os.path.dirname(__file__)), f"files/{name}"),
            dist,
        )


pwsh()
ahk()


print("Installation complete.")
