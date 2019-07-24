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
$output =  @()

$size = "--- a/export/$element/"

git diff $referenceBranch | Select-String -Pattern "---.*$element/.*json" |
ForEach-Object {
    $fileName = $_.Line.Substring($size.Length)
    Write-Output $fileName
    $pathToFile = $rootPath + $fileName

    git diff $referenceBranch -- $pathToFile | Select-String -Pattern "-  " |
    ForEach-Object {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName.TrimEnd('.json')
        $object | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $object | Add-Member -Name "Removed" -MemberType Noteproperty -Value $_.Line.Substring(1)
        $object | Add-Member -Name "Added" -MemberType Noteproperty -Value ""

        $output += $object
    }
    git diff $referenceBranch -- $pathToFile | Select-String -Pattern "\+  " |
    ForEach-Object {
        $object = New-Object -TypeName PSObject
        $object | Add-Member -Name 'Name' -MemberType Noteproperty -Value $fileName.TrimEnd('.json')
        $object | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $object | Add-Member -Name "Removed" -MemberType Noteproperty -Value ""
        $object | Add-Member -Name "Added" -MemberType Noteproperty -Value $_.Line.Substring(1)
        $output += $object
    }

}

write-output $output

$output | Out-File "diff/$element.log"