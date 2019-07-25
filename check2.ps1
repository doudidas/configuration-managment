# Parameters
param(
    [string]$element,
    [string]$platform
)
If (!(test-path "diff")) {
    New-Item -ItemType Directory -Force -Path "diff"
}

$referenceBranch = "remotes/origin/$platform-reference"
$rootPath = "export/$element/"
[array]$output = @()
[array]$overview = @()
$size = "--- a/export/$element/"
git diff $referenceBranch | Select-String -Pattern "(---|\+\+\+).*$element/.*json" -Context 1, 1 | ForEach-Object {
    $fileName = $_.Line.Substring($size.Length)
    write-output "*********** " 
    if ($_.line -match "\+\+\+") {
        if ($_.Context.PostContext[0] -contains "+++ /dev/null") {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName
            $object | Add-Member -Name 'Added' -MemberType Noteproperty -Value "X"
            $object | Add-Member -Name 'Updated' -MemberType Noteproperty -Value ""
            $object | Add-Member -Name 'Removed' -MemberType Noteproperty -Value ""
            $overview += $object
        }
        else {
            $object = New-Object -TypeName PSObject
            $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName
            $object | Add-Member -Name 'Added' -MemberType Noteproperty -Value ""
            $object | Add-Member -Name 'Updated' -MemberType Noteproperty -Value "X"
            $object | Add-Member -Name 'Removed' -MemberType Noteproperty -Value ""
            $overview += $object
        }
    }
    elseif ($_.Context.PostContext[0] -contains "+++ /dev/null") {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName
        $object | Add-Member -Name 'Added' -MemberType Noteproperty -Value ""
        $object | Add-Member -Name 'Updated' -MemberType Noteproperty -Value ""
        $object | Add-Member -Name 'Removed' -MemberType Noteproperty -Value "X"
        $overview += $object
    }
}

Write-Output $overview 
Write-Output $output | Format-Table
if ($output.Count -eq 0 -or $overview.Count -eq 0) {
    Write-Output "No diff for $element"
}
else {
    $overview | Out-File "diff/$element.log"
    Add-Content -Path "diff/$element.log" -Value $output
    exit 1
}