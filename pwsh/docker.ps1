function dps {
    param(
        [Alias("a")]
        [switch] $all = $false
    )
    if ($all) {
        docker ps -a
    }
    else {
        docker ps
    }
}

function doclog {
    param (
        [string] $container,
        [Alias("n")]
        [int] $tail = 500,
        [Alias("f")]
        [switch] $follow = $false
    )

    if ([string]::IsNullOrEmpty($container)) {
        $showall = "-a"
        if ($follow) {
            $showall = ""
        }
        $container = docker ps $showall --format "{{.Names}}" | gum filter --placeholder "Select a container..."
    }
    if ([string]::IsNullOrEmpty($container)) {
        return
    }
    if ($follow) {
        docker logs -f $container
    }
    else {
        docker logs $container --tail $tail
    }
}
