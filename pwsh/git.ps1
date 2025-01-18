function mygitsettings {
    git config user.name "zzztttkkk"
    git config user.email "ztkisalreadytaken@gmail.com"
    git config http.proxy $global:proxy
    git config https.proxy $global:proxy
    Write-Output "REST GIT SETTINGS"
}

function automygitsettings() {
    $name = git config --get user.name
    if ($name -eq "zzztttkkk") {
        return
    }

    $url = git config --get remote.origin.url
    if ($url -match ".*github.com/zzztttkkk/.*") {
        mygitsettings
        return
    }
    if ($url -match ".*git.zzztttkkk.uk/.*") {
        mygitsettings
        return
    }
}

function gs() {
    automygitsettings

    git status
    git submodule foreach --recursive "git status"
}

function cz() {
    automygitsettings

    function timediff() {
        $difftxt = (&w32tm /stripchart /computer:ntp.aliyun.com /dataonly /samples:1)[-1].trim("s").split(", ")[-1];
        return [math]::abs([float]$difftxt)
    }

    $tdiff = timediff
    if ($tdiff -ge 60) {
        Write-Output "System Time Diff With Intnet"
        return;
    }

    $itype = read-host -Prompt "Choice Commit Type:
1: Feat   2: Style    3: Bugfix
4: Chore  5: Refactor 6: Doc
7: Test   8: Try      9: Deploy
0: Init	  a: Perf     b: IgnoreThis
"
    switch ($itype) {
        0 {
            $commit_type = "🎉 Init"
        }
        1 {
            $commit_type = "✨ Feat"
        }
        2 {
            $commit_type = "🎨 Style"
        }
        3 {
            $commit_type = "🐛 Bugfix"
        }
        4 {
            $commit_type = "🧹 Chore"
        }
        5 {
            $commit_type = "🛠 Refactor"
        }
        6 {
            $commit_type = "📚 Doc"
        }
        7 {
            $commit_type = "🧪 Test"
        }
        8 {
            $commit_type = "🤞 Try"
        }
        9 {
            $commit_type = "🚀 Deploy"
        }
        'a' {
            $commit_type = "⚡️ Perf"
        }
        'b' {
            $commit_type = "😏 IgnoreThis"
        }
        default {
            $commit_type = "🧹 Chore"
        }
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
        $content = $content + $line + "\r\n"
        $_cl = $_cl + 1
    }

    $content = $content.trim().trim("\r\n");

    git add *
    if (!$scope) {
        $scope = "/"
    }
    if (!$summary) {
        $summary = "-"
    }
    $m1 = "[" + $commit_type + "] (" + $scope + "): " + $summary

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

function gl() {
    git log -1
}

function pulla() {    
    $branch = &git rev-parse --abbrev-ref HEAD
    git pull origin $branch --allow-unrelated-histories
    git submodule foreach --recursive "pwsh -Command pulla"
}

function fetcha() {    
    git fetch --all
    git submodule foreach --recursive "git fetch --all"
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
        exit
    }

    Write-Output "----------------merge from $target----------------"

    pulla

    $branch = &git rev-parse --abbrev-ref HEAD

    if ($target -eq $branch) {
        Write-Output "----------------same branch----------------"
        exit
    }

    git fetch origin $target
    git merge origin/$target 
}

# git last commit hash
function glch() {
    param (
        [bool] $long
    )
    if ( $long ) {
        git rev-parse HEAD
    }
    else {
        git rev-parse --short HEAD
    }
}

function mktag() {
    param (
        [string] $tag
    )

    if ( ! (Test-Path "./.git") ) {
        Write-Output "Not a git repository"
        return
    }

    if ($tag -eq "") {
        $tag = (gum input --placeholder="tag name").Trim()
    }
    if ($tag -eq "") {
        echo "empty tag name"
        return
    }

    function worktreeclean() {
        $status = git status
        return $status -match ".*nothing to commit, working tree clean$"
    }
	
    if ( !(worktreeclean) ) {
        gum confirm "Working tree is not clean, should make a commit?" --default="no" && cz
    }
	
    do {
        $summary = gum input --placeholder="tag summary"
        $summary = $summary.trim()
    } while ( !$summary )

    git tag -a $tag -m $summary
    git push --tag
}