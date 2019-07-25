
Param([string]$platform, [string]$elementType)

$output = @()
$targetBranch = "$platform-reference"
git add --all
git diff --stat $targetBranch export/$elementType/* | Write-Output
Write-Output $output