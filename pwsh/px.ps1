function global:px {
    param(
        [string]$_px_cmd_name,
        [Alias("h")]
        [switch]$_px_help,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$remain
    )

    $px_dir = (find_px_dir -dir $PWD)
    
    if ([string]::IsNullOrWhiteSpace($_px_cmd_name)) {
        Write-Output "no command name specified"
        return
    }
    
    $target = "$px_dir/$_px_cmd_name.ps1"
    if (Test-Path -Path $target -PathType Leaf) {
        if ($_px_help) {
            help $target
            return
        }
        run_command -px_dir $px_dir -file $target -remain $remain
    }
    else {
        throw "no such command: $_px_cmd_name"
    }
}

function script:find_px_dir {
    param(
        [string]$dir
    )

    $_px_dir = $Global:px_dir
    if ([string]::IsNullOrWhiteSpace($_px_dir)) {
        $_px_dir = "px"
    }

    $target = "$dir/$_px_dir"
    if (Test-Path -Path $target -PathType Container) {
        return $target
    }

    $parent = Split-Path -Path $dir -Parent -ErrorAction SilentlyContinue
    if (([string]::IsNullOrWhiteSpace($parent)) -or ($parent -eq $dir)) {
        throw "no px dir found"
    }
    return (find_px_dir -dir $parent)
}

function script:list_all_commands {
    param (
        [string]$px_dir
    )
    $commands = Get-ChildItem -Path $px_dir -Filter "*.ps1" | ForEach-Object {
        return $_.BaseName
    }
    return $commands | Where-Object { 
        return (($_ -notmatch "^\.") -and ($_ -ne "common")) 
    }
}

function script:args_to_string {
    param (
        [object[]]$argvs
    )

    if (($null -eq $argvs) -or ($argvs.Count -eq 0)) { return "" }

    $result = foreach ($arg in $argvs) {
        $str = [string]$arg
        if ($str.Length -eq 0) { "''"; continue }
        if ($str -match '[\s''"`$@;()\[\]{}]') {
            "'{0}'" -f ($str -replace "'", "''")
        }
        else {
            $str
        }
    }
    return $result -join " "
}

function script:run_command {
    param (
        [string]$px_dir,
        [string]$file,
        [object[]]$remain
    )

    Push-Location (Split-Path -Path $px_dir -Parent)
    try {
        $argvs = args_to_string $remain
        $expr = [scriptblock]::create("& `"$file`" $argvs")
        $begin = [DateTime]::Now
        & $expr
        $end = [DateTime]::Now
        $elapsed = $end - $begin
        Write-Host ">>>>>>>>>>" -ForegroundColor Green -NoNewline
        Write-Host " px exec ``" -NoNewline
        Write-Host "$([System.IO.Path]::GetFileNameWithoutExtension($file))" -ForegroundColor Cyan -NoNewline
        Write-Host "``, elapsed: " -NoNewline
        Write-Host "$elapsed" -ForegroundColor Cyan
    }
    catch {
        throw $_
    }
    finally {
        Pop-Location
    }
}

Register-ArgumentCompleter -CommandName px -ParameterName _px_cmd_name -ScriptBlock {
    param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
    
    try {
        $px_dir = find_px_dir -dir $PWD
        $cmds = list_all_commands -px_dir $px_dir
        $cmds | Where-Object { $_ -like "$wordToComplete*" } | ForEach-Object {
            [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
        }
    }
    catch {
    }
}