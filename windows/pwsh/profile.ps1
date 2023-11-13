$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User")

& $HOME/.pyenv/Scripts/activate.ps1

Set-Alias which Get-Command
Set-Alias grep Select-String

function google ($search) {
	$url = "https://www.google.com/search?q=" + $search
	Start-Process $url
}

function bing ($search) {
	$url = "https://cn.bing.com/search?ensearch=1&q=" + $search
	Start-Process $url
}

$global:proxy = "";

function useproxy() {
	$env:http_proxy = $global:proxy
	$env:https_proxy = $global:proxy
}

function resetproxy() {
	$env:http_proxy = ""
	$env:https_proxy = ""
}

if (get-command gum -errorAction SilentlyContinue) {
}
else {
	go install github.com/charmbracelet/gum@latest
}


$global:__sshcMap = @{};
$global:dockerExe = "docker"
$global:dockerComposeExe = "docker-compose"

# ssh connect
function sshc {
	param (
		[String] $name
	)
	ssh $global:__sshcMap[$name];
}

# ssh upload
function sshup([String] $name, [String] $local, [String] $remote) {
	$temp = $global:__sshcMap[$name]
	$print_remote = $false;
	if ([string]::IsNullOrEmpty($remote)) {
		$remote = "/tmp/" + [guid]::NewGuid().ToString();
		$print_remote = $true;
	}
	$temp = $temp + ":" + $remote
	scp $local $temp
	if ($print_remote) {
		Write-Output "Remote: $remote"
	}
}

# ssh download
function sshdown([String] $name, [String] $remote, [String] $local) {
	$temp = $global:__sshcMap[$name]
	$print_local = $false;
	if ([string]::IsNullOrEmpty($local)) {
		$local = $env:USERPROFILE + "/Downloads/" + [guid]::NewGuid().ToString();
		$print_local = $true;
	}

	$temp = $temp + ":" + $remote
	scp $temp $local
	if ($print_local) {
		Write-Output "Local: $local"
	}
}

# docker group

function containerd(){
	Invoke-Expression "$global:dockerExe $args"
}

function compose() {
	Invoke-Expression "$global:dockerComposeExe $args"
}

function pgcli {
	param (
		[String] $name
	)

	Invoke-Expression "$global:dockerExe start postgresdb"
	Invoke-Expression "$global:dockerExe exec -it --user postgres postgresdb psql $name" 
}

function rcli {
	Invoke-Expression "$global:dockerExe start redisdb"
	Invoke-Expression "$global:dockerExe exec -it redisdb redis-cli"
}

function mgcli {
	param (
		[String] $name
	)

	Invoke-Expression "$global:dockerExe start mongodb"
	Invoke-Expression "$global:dockerExe exec -it mongodb mongosh -u root -p 123456 $name"
}

# git group

function gsetting {
	git config user.name "zzztttkkk"
	git config user.email "ztkisalreadytaken@gmail.com"
	git config http.proxy $global:proxy
	git config https.proxy $global:proxy
}

function ___autogs(){
	$url = git config --get remote.origin.url
	if($url -match ".*github.com/zzztttkkk.*"){
		gsetting
	}
}

function gs() {
	___autogs

	git status
	git submodule foreach --recursive "git status"
}

function cz() {
	___autogs

	function local:timeDiffFromIntnet() {
		$difftxt = (&w32tm /stripchart /computer:ntp.aliyun.com /dataonly /samples:1)[-1].trim("s").split(", ")[-1];
		return [math]::abs([float]$difftxt)
	}

	$tdiff = timeDiffFromIntnet
	if ($tdiff -ge 60) {
		Write-Output "System Time Diff From Intnet"
		return;
	}

	$itype = read-host -Prompt "Choice Commit Type:
1: feat   2: fix    3: chore
4: refactor 5: docs 6: style
7: test   8: pref   9: init
0: tag
"
	switch ($itype) {
		0 {
			$commit_type = "🔖tag"
		}
		1 {
			$commit_type = "✨feat"
		}
		2 {
			$commit_type = "🐛fix"
		}
		3 {
			$commit_type = "🧱chore"
		}
		4 {
			$commit_type = "🔨refactor"
		}
		5 {
			$commit_type = "📚docs"
		}
		6 {
			$commit_type = "🌅style"
		}
		7 {
			$commit_type = "🧪test"
		}
		8 {
			$commit_type = "🚀pref"
		}
		9 {
			$commit_type = "🎉init"
		}
		default {
			$commit_type = "🧱chore"
		}
	}

	$scope = read-host -Prompt "Scope"
	$summary = read-host -Prompt "Summary"
	$scope = $scope.trim()
	$summary = $summary.trim()

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

function pulla() {    
	$branch = &git rev-parse --abbrev-ref HEAD
	git pull origin $branch --allow-unrelated-histories
	git submodule foreach --recursive "pwsh -Command pulla"
}

function pushc() {
	$branch = &git rev-parse --abbrev-ref HEAD
	git push origin $branch
}

function gcheckout() {
	param (
		[string]$target
	)
	git checkout -B $target
	git submodule foreach --recursive "git checkout -B $target"
}

function mergefrom() {
	param (
		[string]$target
	)

	Write-Output "----------------merge from $target----------------"

	if ($target -eq "") {
		exit
	}

	pulla

	$branch = &git rev-parse --abbrev-ref HEAD

	if ($target -eq $branch) {
		exit
	}

	git fetch origin $target
	git merge origin/$target 
}



function wslip() {
	wsl hostname -I
}

function nc() {
	ncat $args
}

function fexp() {
	param (
		[string]$target = "."
	)

	explorer $target
}

function loop() {
	param (
		[Int] $times
	)

	for ($i = 1; $i -le $times; $i++) {
		&$args[0] ($args | select-object -skip 1)
	}
}

function urandom() {
	param (
		[Int] $length = 16
	)
	python -c "print(__import__('base64').b64encode(__import__('os').urandom($length)).decode()[:$length])"
}

function hash() {
	param (
		[String] $txt = "",
		[String] $algname = "",
		[String] $outputtype = ""
	)

	if ($txt -eq "") {
		$txt = &gum input --placeholder="input some text in utf8"
	}

	if ($algname -eq "") {
		$tmp = &python -c 'print(" ".join(sorted(list(__import__("hashlib").algorithms_available))))'
		$algs = $tmp -split " "
		$algname = &gum choose --selected="md5" $algs
	}

	if ($outputtype -eq "") {
		$outputtype = &gum choose --selected="hex" "base64" "bin" "hex" 
	}

	switch ($outputtype) {
		"hex" {
			python -c "print(__import__('hashlib').$algname('''$outputtype'''.encode('utf8')).hexdigest())"
		}
		"bin" {
			python -c "print(__import__('hashlib').$algname('''$outputtype'''.encode('utf8')).digest())"
		}
		"base64" {
			python -c "print(__import__('base64').b64encode(__import__('hashlib').$algname('''$outputtype'''.encode('utf8')).digest()).decode())"
		}
	}
	
}

function netlistening() {
	netstat -ano -p TCP | grep LISTENING
}

function fslink() {
	param (
		[string]$link,
		[string]$target
	)

	New-Item -Path $link -ItemType SymbolicLink -Value $target
}

function rmfs([String] $path){
	if($path -eq "") {
		return;
	}
	Remove-Item -Path $path -r --force
}

$global:godot_projects_path = ""

function gdps(){
	$projects = Get-ChildItem -Directory $global:godot_projects_path | foreach-object {$_.Name}
	$project = &gum choose $projects
	Set-Location "$global:godot_projects_path/$project"
}


$local = "$PSScriptRoot/local.ps1"
if (Test-Path -Path $local) {
	. $local
}
