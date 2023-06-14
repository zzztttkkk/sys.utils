import os

os.mkdir("/run/postgresql")
os.system("chown postgres:postgres /run/postgresql")

os.chdir("/var/lib/postgresql")


def pgexec(cmd: str):
    return os.system(f"su-exec postgres {cmd}")


def make_pgs(name: str):
    if name == "main":
        port = 5432
    else:
        port = 5433

    if name == "main":
        pgexec(f"mkdir ./{name}")
        pgexec(f"chmod 0700 ./{name}")
        pgexec(f"initdb -D ./{name}")
    else:
        pgexec(
            f"pg_basebackup -h 127.0.0.1 -p 5432 -U replica_user -w -X stream -v -R -D ./{name}"
        )

    pgexec(f'echo "host all all 0.0.0.0/0 md5" >> ./{name}/pg_hba.conf')
    pgexec(f"""echo "listen_addresses='*'" >> ./{name}/postgresql.conf""")
    pgexec(f'echo "port = {port}" >> ./{name}/postgresql.conf')
    pgexec(f"mkdir /tmp/pg{name}")

    with open(f"./{name}/postgresql.conf", "r", encoding="utf8") as pgconf:
        val = pgconf.read()
        val = val.replace(
            "unix_socket_directories = '/run/postgresql'",
            f"unix_socket_directories = '/tmp/pg{name}'",
        )

    with open(f"./{name}/postgresql.conf", "w", encoding="utf8") as pgconf:
        pgconf.seek(0)
        pgconf.write(val)

    os.system(f"chown postgres:postgres ./{name}/postgresql.conf")

    pgexec(f"pg_ctl start -D ./{name}")

    if name == "main":
        pgexec(
            """psql -h /tmp/pgmain -c "create role replica_user with replication login password '123456'\""""
        )
        pgexec(
            f'echo "host replication replica_user 127.0.0.1/32 md5" >> ./{name}/pg_hba.conf'
        )
        pgexec(f"pg_ctl restart -D ./{name}")


make_pgs("main")
make_pgs("sub")
