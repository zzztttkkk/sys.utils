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
        exit
    }

    if ($items.Count -eq 1) {
        $name = $items
    }
    else {
        $name = gum choose $items
    }

    if ( [string]::IsNullOrEmpty($name) ) {
        exit 1
    }

    Start-Process -NoNewWindow code $root/$name
    exit
}

$global:__code_projects_dir = ""

function vsc() {
    param (
        [String] $search = ""
    )
    __vscodechoose $search $global:__code_projects_dir
}
