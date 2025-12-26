function global:px {
    param(
        [string]$name,
        [switch]$help,

        [Parameter(ValueFromRemainingArguments = $true)]
        [object[]]$remain
    )

    $px_dir = (find_px_dir -dir $PWD)
    
    if ([string]::IsNullOrWhiteSpace($name)) {
        Write-Output "no command name specified"
        return
    }
    
    $target = "$px_dir/$name.ps1"
    if (Test-Path -Path $target -PathType Leaf) {
        if ($help) {
            help $target
            return
        }
        run_command -px_dir $px_dir -name $name -remain $remain
    }
    else {
        throw "no such command: $name"
    }
}

function script:find_px_dir {
    param(
        [string]$dir
    )

    $target = "$dir/px"
    if (Test-Path -Path $target -PathType Container) {
        return $target
    }

    $parent = Split-Path -Path $dir -Parent
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
    $tmp = $argvs | ForEach-Object {
        $str = "$_"
        if ($str -match " ") {
            $str = $str -replace "`"", "`"`""
            return "`"$str`""
        }
        else {
            return $str
        }
    }
    return $tmp -join " "
}

function script:run_command {
    param (
        [string]$px_dir,
        [string]$name,
        [object[]]$remain
    )

    Push-Location (Split-Path -Path $px_dir -Parent)
    try {
        $argvs = args_to_string $remain
        $expr = "& ""$px_dir/$name.ps1"" $argvs"
        $begin = [DateTime]::Now
        Invoke-Expression $expr
        $end = [DateTime]::Now
        $elapsed = $end - $begin
        Write-Output "px exec elapsed: $elapsed"
    }
    catch {
        throw $_
    }
    finally {
        Pop-Location
    }
}

Register-ArgumentCompleter -CommandName px -ParameterName name -ScriptBlock {
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