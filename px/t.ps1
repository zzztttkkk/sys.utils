param(
    [string] $name,
    [int] $count
)

Write-Host "VVVVVVVVV"

for ($i = 0; $i -lt $count; $i++) {
    Write-Output "hello $name $i" 
}