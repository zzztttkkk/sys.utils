function global:ensuremodule {
    param (
        [String] $name
    )

    switch ($name) {
        "toml" {
            $info = Get-PSResource -Name PSToml -ErrorAction SilentlyContinue
            if ( $null -eq $info ) {
                Install-PSResource -Name PSToml -Scope CurrentUser
            }
            Import-Module -Name PSToml
        }
    }
}