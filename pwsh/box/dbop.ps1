function script:_dbop {
    param (
        [String] $dbkind = "",
        [String] $opkind = ""
    )

    $allkinds = Get-ChildItem -Attributes Directory | Select-Object -ExpandProperty Name
    $allkinds += "all"

    if ($dbkind -eq "") {
        $dbkind = $(gum filter $allkinds)
        if ($null -eq $dbkind) {
            return;
        }
    }

    if ($opkind -eq "") {
        $opkind = $(gum filter start stop exec)
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
            "mongotx" {
                docker exec -it mongotx mongosh -u root -p 123456
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
            "valkey" {
                docker exec -it valkey valkey-cli
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

    switch ($dbkind) {
        "all" { 
            foreach ($kind in $allkinds) {
                if ($kind -ne "all") {
                    Push-Location /mnt/d/dev/containers/$kind
                    docker compose $opkind
                    Pop-Location
                }
            }
        }
        Default {
            Push-Location /mnt/d/dev/containers/$dbkind
            docker compose $opkind
            Pop-Location
        }
    }
}

function global:dbop {
    param (
        [String] $dbkind = "",
        [String] $opkind = ""
    )

    Push-Location /mnt/d/dev/containers
    _dbop $dbkind $opkind
    Pop-Location
}
