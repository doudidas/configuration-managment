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

Write-Output $overview | Format-List 

# if ($output.Count -eq 0) {
#     Write-Output "No diff for $element"
# }
# else {
#     Write-Output $output | Format-Table
#     $output | Out-File "diff/$element.log"
#     exit 1
# }


function getupdateDetail {
    param (
        [string]$pathToFile
    )
    $return = @()
    git diff $referenceBranch -- $pathToFile | Select-String -Pattern "-  " |
    ForEach-Object {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName.TrimEnd('.json')
        $object | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $object | Add-Member -Name "Removed" -MemberType Noteproperty -Value $_.Line.Substring(1)
        $object | Add-Member -Name "Added" -MemberType Noteproperty -Value ""
        $return += $object
    }
    git diff $referenceBranch -- $pathToFile | Select-String -Pattern "\+  " |
    ForEach-Object {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName.TrimEnd('.json')
        $object | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $object | Add-Member -Name "Removed" -MemberType Noteproperty -Value ""
        $object | Add-Member -Name "Added" -MemberType Noteproperty -Value $_.Line.Substring(1)
        $return += $object
    }
    return $return
}