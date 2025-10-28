$global:__code_projects_dir = ""

function vsc() {
    param (
        [String] $search = ""
    )

    function __vscodechoose() {
        param (
            [String] $search,
            [String] $root
        )

        $items = get-childitem -path $root | select-object -expandproperty name
        if ( -not [string]::IsNullOrEmpty($search) ) {
            $items = $items | where-object { $_ -like "*$search*" }
        }
        if ($items.Count -eq 0) {
            return
        }

        if ($items.Count -eq 1) {
            $name = $items
        }
        else {
            $name = gum filter $items
        }

        if ( [string]::IsNullOrEmpty($name) ) {
            return
        }

        Start-Process -FilePath code -ArgumentList $root/$name -WindowStyle Hidden
    }

    __vscodechoose $search $global:__code_projects_dir
}
