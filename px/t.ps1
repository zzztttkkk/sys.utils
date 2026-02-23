param(
    [string] $name,
    [int] $count
)

for ($i = 0; $i -lt $count; $i++) {
    Write-Output "hello $name $i" 
}