function dbop {
    param (
        [String] $dbkind = "",
        [String] $opkind = ""
    )

    if ($dbkind -eq "") {
        $dbkind = $(gum choose mssql oracle ibmdb2 clickhouse mongo postgres mysql redis es all)
        if ($null -eq $dbkind) {
            return;
        }
    }

    if ($opkind -eq "") {
        $opkind = $(gum choose start stop exec)
        if ($null -eq $opkind) {
            return;
        }
    }

    if ($opkind -eq "exec") {
        switch ($dbkind) {
            "mysql" {
                docker exec -it mysql mysql -u root -p123456
                return
            }
            "mongo" {
                docker exec -it mongo mongosh -u root -p 123456
                return
            }
            "postgres" {
                docker exec -it -u postgres postgres psql
                return
            }
            "redis" {
                docker exec -it redis redis-cli
                return
            }
            "oracle" {
                docker exec -it oracle sqlplus "C##DATA/Ora_123456@localhost/FREE"
                return
            }
            "mssql" {
                docker exec -it mssql /opt/mssql-tools18/bin/sqlcmd -No -S localhost -U SA -P "msSql_123456"
                return
            }
            "clickhouse" {
                docker exec -it clickhouse clickhouse-client --user=default --password=123456
                return
            }
            "ibmdb2" {
                docker exec -it -u db2inst1 ibmdb2 bash
                return
            }
            Default {}
        }

        return;
    }

    $orgcwd = $PWD

    switch ($dbkind) {
        "all" { 
            Set-Location /mnt/d/dev/containers/mssql
            docker compose $opkind

            Set-Location /mnt/d/dev/containers/oracle
            docker compose $opkind

            Set-Location /mnt/d/dev/containers/clickhouse
            docker compose $opkind

            Set-Location /mnt/d/dev/containers/es
            docker compose $opkind

            Set-Location /mnt/d/dev/containers/normal
            docker compose $opkind
        }
        "es" {
            Set-Location /mnt/d/dev/containers/$dbkind
            docker compose $opkind
        }
        "ibmdb2" {
            Set-Location /mnt/d/dev/containers/$dbkind
            docker compose $opkind
        }
        "mssql" {
            Set-Location /mnt/d/dev/containers/$dbkind
            docker compose $opkind
        }
        "oracle" {
            Set-Location /mnt/d/dev/containers/$dbkind
            docker compose $opkind
        }
        "clickhouse" {
            Set-Location /mnt/d/dev/containers/$dbkind
            docker compose $opkind
        }
        "mysql" {
            Set-Location /mnt/d/dev/containers/normal
            docker compose $opkind $dbkind
        }
        "mongo" {
            Set-Location /mnt/d/dev/containers/normal
            docker compose $opkind $dbkind
        }
        "redis" {
            Set-Location /mnt/d/dev/containers/normal
            docker compose $opkind $dbkind
        }
        "postgres" {
            Set-Location /mnt/d/dev/containers/normal
            docker compose $opkind $dbkind
        }
        Default {
            Write-Output "Unexpected DBKind: $dbkind"
            return
        }
    }

    Set-Location $orgcwd
}