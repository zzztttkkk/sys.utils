import os
from flask import Flask, request


app = Flask(__name__)

os.system(f"su-exec postgres pg_ctl start -D /var/lib/postgresql/main")
os.system(f"su-exec postgres pg_ctl start -D /var/lib/postgresql/sub")


@app.get("/exec")
def exec():
    cmds = request.args.getlist("cmd")
    exc = None
    try:
        os.system(" ".join(cmds))
    except Exception as e:
        exc = e

    if exc:
        return f"{exc}"

    return "ok"


@app.get("/pg/{name:str}/{action:str}")
def pgctl(name, action):
    cmd = f"su-exec postgres pg_ctl {action} -D /var/lib/postgresql/{name}"
    os.system(cmd)
    return "ok"


app.run(host="0.0.0.0", port=80)
