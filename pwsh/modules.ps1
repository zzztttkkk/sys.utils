function script:ensure {
    param (
        [String] $name
    )
    $info = Get-PSResource -Name $name -ErrorAction SilentlyContinue
    if ( $null -eq $info ) {
        Install-PSResource -Name $name -Scope CurrentUser
    }
    Import-Module -Name $name
}

function global:ensuremodule {
    param (
        [String] $name
    )

    switch ($name) {
        "toml" {
            ensure "PSToml"
        }
        "readline" {
            ensure "PSReadLine"
            ensure "CompletionPredictor"
        }
        default {
            throw "Unknown module: $name"
        }
    }
}
