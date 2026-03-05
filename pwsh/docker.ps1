function dps {
    param(
        [Alias("a")]
        [switch] $all = $false
    )
    $fmt = "table {{.Id}}\t{{.Names}}\t{{.Image}}\t{{.ContainerID}}\t{{.Status}}\t{{.Ports}}"
    if ($all) {
        docker ps -a --format $fmt
    }
    else {
        docker ps --format $fmt
    }
}

function dlog {
    param (
        [string] $container,
        [Alias("n")]
        [int] $tail = 500,
        [Alias("f")]
        [switch] $follow = $false
    )

    $psargs = @()
    if ([string]::IsNullOrEmpty($container)) {
        if (-not($follow)) {
            $psargs += "-a"
        }
        $psargs += "--format"
        $psargs += "{{.Names}}"
        $container = docker ps $psargs | gum filter --placeholder "Select a container..."
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
