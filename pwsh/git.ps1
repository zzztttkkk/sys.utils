$global:gitauth = @{}

function updategitsettings() {
    if ($global:gitauth.Count -lt 0) {
        $name = gum filter $global:gitauth.Keys
        if ([string]::IsNullOrEmpty($name)) {
            return
        }
        $email = $global:gitauth[$name]
        if ([string]::IsNullOrEmpty($email)) {
            return
        }

        git config user.name $name
        git config user.email $email
    }
    if (confirm "Use proxy?") {
        git config http.proxy $global:proxy
        git config https.proxy $global:proxy    
    }
    else {
        git config --unset http.proxy
        git config --unset https.proxy
    }
}

function gs() {
    git status
    git submodule foreach --recursive "git status"
}

function cz() {
    param (
        [bool]$nonet = $false
    )

    function timediff() {
        if ($IsWindows) {
            $difftxt = (&w32tm /stripchart /computer:ntp.aliyun.com /dataonly /samples:1)[-1].trim("s").split(", ")[-1];
            return [math]::abs([float]$difftxt)
        }

        if ($IsLinux) {
            $ntptimestring = ((ntpdate -q ntp.aliyun.com) -split ' ')[0..2] | join-string -Separator ' '
            $ntptimestamp = [int]$(date --date $ntptimestring +%s)
            $hosttimestamp = [int]$(date --date "now" +%s)
            return [math]::abs($hosttimestamp - $ntptimestamp)
        }
    }

    if (-not $nonet) {
        $tdiff = timediff
        if ($tdiff -ge 60) {
            Write-Output "System Time Diff With Intnet"
            return;
        }
    }

    [string[]] $allctypes = @(
        "🚧 WIP", "♿ Aiiy", "✨ Feat", "🎨 Style",
        "🐛 Bugfix", "🛠 Refactor",
        "📚 Doc", "🧪 Test", "🎉 Release", "🌐 I18n"
        "⚡️ Perf", "🗑 Reverts", "🧹 Chore", "⚙️ Ci"
    )
    $ctype = gum filter $allctypes
    if ($null -eq $ctype) {
        return 
    }
    $scope = read-host -Prompt "Scope"
    $summary = ""
    do {
        $summary = read-host -Prompt "Summary"
        $summary = $summary.trim()
    } while ( !$summary )

    $scope = $scope.trim()

    $_cl = 0;
    $content = "";
    $_el = 0;
    while (1) {
        if ($_cl -eq 0) {
            $line = read-host -Prompt "Content"
        }
        else {
            $line = read-host
        }
        if ($line.trim() -eq "") {
            $_el = $_el + 1;
            if ($_el -eq 2) {
                break;
            }
        }
        $content = $content + $line + "`n"
        $_cl = $_cl + 1
    }

    $content = $content.trim();

    git add -A
    if (!$scope) {
        $scope = "/"
    }
    if (!$summary) {
        $summary = "-"
    }
    $m1 = "[" + $ctype + "] (" + $scope + "): " + $summary

    if ($content -eq "") {
        git commit -m $m1
    }
    else {
        git commit -m $m1 -m $content
    }
}

function grh() {
    git reset --hard
}

function pulla() {    
    $branch = &git rev-parse --abbrev-ref HEAD
    git pull origin $branch --allow-unrelated-histories
    git submodule foreach --recursive "pwsh -Command pulla"
}

function fa() {    
    git fetch --all
    git submodule sync --recursive
    git fetch --all --prune --recurse-submodules
}

function pushc() {
    $branch = &git rev-parse --abbrev-ref HEAD
    git push origin $branch
    glch
}

function mergefrom() {
    param (
        [string]$target
    )
    if ($target -eq "") {
        return
    }

    $branch = &git rev-parse --abbrev-ref HEAD
    if ($target -eq $branch) {
        Write-Output "----------------same branch----------------"
        return
    }

    if (!(worktreeclean)) {
        Write-Output "Working tree is not clean, please commit or stash your changes."
        return
    }

    if (confirm ">>>>>>>>>>>>>>>>> Merge from $target to $branch ? <<<<<<<<<<<<<<<<<<<<") {
        git fetch origin $target
        git merge origin/$target 
    }
}

# git last commit hash
function glch() {
    param (
        [switch] $long
    )
    if ( $long ) {
        git rev-parse HEAD
    }
    else {
        git rev-parse --short HEAD
    }
}

function script:worktreeclean() {
    $status = git status --porcelain
    return [string]::IsNullOrWhiteSpace($status)
}

function mktag() {
    param (
        [string] $tag
    )

    if ([string]::IsNullOrWhiteSpace($tag)) {
        $tag = (gum input --placeholder="tag name").Trim()
    }
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Output "empty tag name, canceled"
        return
    }
	
    if ( !(worktreeclean) ) {
        gum confirm "Working tree is not clean, should make a commit?" --default="no" && cz
    }
    if ( !(worktreeclean) ) {
        Write-Output "working tree is not clean, canceled"
        return
    }
	
    $summary = gum input --placeholder="tag summary"
    $summary = $summary.trim()
    if ([string]::IsNullOrWhiteSpace($summary)) {
        Write-Output "empty tag summary, canceled"
        return
    }

    git tag -a $tag -m $summary
    git push origin $tag
}


function deltag() {
    param (
        [string] $tag
    )
    if ($tag -eq "") {
        $tag = git tag -l | gum filter
    }
    if ([string]::IsNullOrWhiteSpace($tag)) {
        Write-Output "empty tag name, canceled"
        return
    }
    git tag -d $tag
    git push origin --delete $tag
}
