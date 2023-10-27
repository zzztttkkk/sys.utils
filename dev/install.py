import sys
import os
import pathlib
import shutil


def pwsh():
    dp = os.path.join(pathlib.Path.home(), "Documents/PowerShell")
    if not os.path.exists(dp):
        os.makedirs(dp)

    dist_path = os.path.join(dp, "Microsoft.PowerShell_profile.ps1")
    src_path = os.path.join(
        os.path.dirname(os.path.dirname(__file__)),
        "windows/pwsh/profile.ps1",
    )

    shutil.copyfile(src_path, dist_path)


def ahk():
    dist = f"{os.path.expanduser('~')}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/Startup/.ahk"
    if os.path.exists(dist):
        return
    shutil.copyfile(
        os.path.join(os.path.dirname(os.path.dirname(__file__)), "files/.ahk"), dist
    )


def docker():
    dp = os.path.join(pathlib.Path.home(), "Documents/DevContainers")
    if not os.path.exists(dp):
        os.makedirs(dp)

    src_root_path = os.path.dirname(os.path.dirname(__file__))
    dist_root_path = dp
    shutil.copytree(f"{src_root_path}/dockers", dist_root_path, dirs_exist_ok=True)


docker()

if sys.platform == "win32":
    pwsh()
    ahk()
