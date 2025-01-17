& $HOME/.pyenv/Scripts/activate.ps1
fnm env --use-on-cd | Out-String | Invoke-Expression

Set-Alias which Get-Command
Set-Alias grep Select-String
Set-Alias ll ls

$ENV:ETC_PATH = "C:/Windows/System32/drivers/etc"

function google ($search) {
	$url = "https://www.google.com/search?q=" + $search
	Start-Process "msedge.exe" -ArgumentList $url
}

function transce ($txt) {
	$url = "https://translate.google.com/?sl=zh-CN&tl=en&text=" + $txt
	Start-Process "msedge.exe" -ArgumentList $url
}

function transec ($txt) {
	$url = "https://translate.google.com/?tl=zh-CN&sl=en&text=" + $txt
	Start-Process "msedge.exe" -ArgumentList $url
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

$global:__sshcAuthMap = @{};
$global:__sshcPortMap = @{};

# ssh connect
function sshc {
	param (
		[String] $name
	)

	$port = $global:__sshcPortMap[$name]
	if (!$port) {
		$port = 22 
	}

	$auth = $global:__sshcAuthMap[$name]
	if (!$auth) {
		echo "empty auth for $name"
		return
	}

	ssh $auth -p $port $args
}

# ssh upload
function sshup([String] $name, [String] $local, [String] $remote) {
	$temp = $global:__sshcAuthMap[$name]
	if (!$temp) {
		echo "empty auth for $name"
		return
	}

	$port = $global:__sshcPortMap[$name]
	if ( !$port ) {
		$port = 22 
	}

	$print_remote = $false;
	if ([string]::IsNullOrEmpty($remote)) {
		$remote = "/tmp/" + [guid]::NewGuid().ToString();
		$print_remote = $true;
	}
	$temp = $temp + ":" + $remote
	scp -P $port $local $temp
	if ($print_remote) {
		Write-Output "Remote: $remote"
	}
}

# ssh download
function sshdown([String] $name, [String] $remote, [String] $local) {
	$temp = $global:__sshcAuthMap[$name]
	if (!$temp) {
		echo "empty auth for $name"
		return
	}

	$port = $global:__sshcPortMap[$name]
	if ( !$port ) {
		$port = 22 
	}

	$print_local = $false;
	if ([string]::IsNullOrEmpty($local)) {
		$local = $env:USERPROFILE + "/Downloads/" + [guid]::NewGuid().ToString();
		$print_local = $true;
	}

	$temp = $temp + ":" + $remote
	scp -P $port $temp $local
	if ($print_local) {
		Write-Output "Local: $local"
	}
}

# docker group
function pgcli {
	param (
		[String] $name
	)

	Invoke-Expression "docker start postgresdb"
	Invoke-Expression "docker exec -it --user postgres postgresdb psql $name"
}

function mycli {
	param (
		[String] $name
	)

	if ($name -eq "") {
		$name = "mysql"
	}

	Invoke-Expression "docker start mysqld"
	Invoke-Expression "docker exec -it mysqld mysql -u root --password=123456 --auto-rehash -D $name"
}

function rcli {
	Invoke-Expression "docker start redisdb"
	Invoke-Expression "docker exec -it redisdb redis-cli"
}

function mgcli {
	param (
		[String] $name
	)

	Invoke-Expression "docker start mongodb"
	Invoke-Expression "docker exec -it mongodb mongosh -u root -p 123456 $name"
}

# git group
function mygitsettings {
	git config user.name "zzztttkkk"
	git config user.email "ztkisalreadytaken@gmail.com"
	git config http.proxy $global:proxy
	git config https.proxy $global:proxy
	echo "REST GIT SETTINGS"
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
	} while( !$summary )

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

function gl(){
	git log -1
}

function pulla() {    
	$branch = &git rev-parse --abbrev-ref HEAD
	git pull origin $branch --allow-unrelated-histories
	git submodule foreach --recursive "pwsh -Command pulla"
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
	} else {
		git rev-parse --short HEAD
	}
}

function mktag(){
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
	} while( !$summary )

	git tag -a $tag -m $summary
	git push --tag
}

function wslip() {
	wsl hostname -I
}

function nc() {
	param(
		[string] $_host,
		[int] $_port
	)

	Test-NetConnection -ComputerName $_host -Port $_port
}

# explorer.exe
function fexp {
	param (
		[string]$target = "."
	)
	$path = resolve-path $target
	explorer.exe $path
}

function fexpetc() {
	fexp $ENV:ETC_PATH
}

function exprestart(){
	taskkill /f /im explorer.exe
	start explorer.exe
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

function hex(){
	param (
		[int] $num = 0
	)
	$val = "{0:X}" -f $num
	echo $val
}

function listeningports() {
	netstat -ano -p TCP | grep LISTENING
}

function netreset() {
	ipconfig /flushdns
	ipconfig /registerdns
	ipconfig /release
	ipconfig /renew
	netsh winsock reset
}

function __vscodechoose() {
	param (
		[String] $search,
		[String] $root
	)

	$items = get-childitem -path $root | select-object -expandproperty name
	if ( -not [string]::IsNullOrEmpty($search) ) {
		$items = $items | where-object { $_ -like "*$search*"}
	}
	if ($items.Count -eq 0) {
		return
	}

	if ($items.Count -eq 1) {
		$name = $items
	}else{
		$name = gum choose $items
	}

	if ( [string]::IsNullOrEmpty($name) ) {
		return
	}

	code $root/$name
	exit
}

$global:__code_projects_dir = ""

function vsc() {
	param (
		[String] $search = ""
	)
	__vscodechoose $search $global:__code_projects_dir
}

function fkill(){
	param (
		[String] $val = "",
		[String] $prop = "ProcessName",
		[String] $op = "eq"
	)
	if ($val -eq "" ) {
		return
	}
	$op = "-${op}"
	$operators = @('-eq', '-ne', '-gt', '-lt', '-ge', '-le', '-like', '-notlike', '-match', '-notmatch', '-in', '-notin', '-and', '-or', '-not', '-is', '-isnot', '-ceq', '-cne', '-cgt', '-clt', '-cge', '-cle', '-clike', '-cnotlike', '-cmatch', '-cnotmatch')
	if ($operators -notcontains $op) {
		throw "bad operator: $op"
	}
	$ids = Invoke-Expression "ps | where -Property $prop -Value $val $op | select -ExpandProperty Id"
	foreach ( $tmpid in $ids ) {
		try{
			stop-process -id $tmpid
		}catch{
			Write-Warning "Failed to terminate process: $tmpid"
		}
	}
}

function cacheclean(){
	# node
	echo ">>>>>>>>>>>> npm <<<<<<<<<<<<<<<"
	npm cache clean --force
	echo ">>>>>>>>>>>> pnpm <<<<<<<<<<<<<<<"
	pnpm cache delete
	pnpm store prune
	try {
		echo ">>>>>>>>>>>> nodegyp <<<<<<<<<<<<<<<"
		rm -r -fo ~/AppData/Local/node-gyp
	}catch{
		""
	}

	# go
	echo ">>>>>>>>>>>> go <<<<<<<<<<<<<<<"
	go clean -cache
	try {
		echo ">>>>>>>>>>>> gopls <<<<<<<<<<<<<<<"
		rm -r -fo ~/AppData/Local/gopls
	}catch{
		""
	}

	# rust
	echo ">>>>>>>>>>>> rust <<<<<<<<<<<<<<<"
	cargo cache -a
}


$local = "$PSScriptRoot/local.ps1"
if (Test-Path -Path $local) {
	. $local
}

if ( ! $global:__code_projects_dir ) {
	$global:__code_projects_dir = "d:/codes"
}