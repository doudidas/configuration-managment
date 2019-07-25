# Parameters
param(
    [string]$element,
    [string]$platform,
    [string]$verbose
)
If (!(test-path "diff")) {
    New-Item -ItemType Directory -Force -Path "diff"
}

$referenceBranch = "remotes/origin/$platform-reference"

git diff $referenceBranch -- "export/$element/*.json" | Out-File -FilePath "diff/$element"
[array]$lines = Get-Content "diff/$element"
$overview = @()
$details = @()
$trimSize = 14 + $element.Length 
$tmp = New-Object -TypeName PSObject
for ($i = 0; $i -lt $lines.Count; $i++) {
    $current = $lines[$i]
    if ($current -match "^diff --git") {
        $overview += $tmp
        $tmp = New-Object -TypeName PSObject
        $tmp | Add-Member -Name 'Name' -MemberType Noteproperty -Value ''
        $tmp | Add-Member -Name 'Added' -MemberType Noteproperty -Value ''
        $tmp | Add-Member -Name 'Updated' -MemberType Noteproperty -Value ''
        $tmp | Add-Member -Name 'Deleted' -MemberType Noteproperty -Value ''
    }
    elseif ($current -match "^deleted file mode [0-9].*") {
        $tmp.Deleted = '   x'
    }
    elseif ($current -match "^new file mode [0-9].*") {
        $tmp.Added = '  x'
    }
    elseif ($current -match "^index [0-9a-z].*..[0-9a-z].* [0-9a-z].*") {
        $tmp.Updated = '   x'
    }
    elseif ($current -match "^(---|\+\+\+)") {
        if ($current -notmatch "(---|\+\+\+) /dev/null") {
            $tmp.Name = $current.Substring($trimSize).trim()
        }
    }
    elseif ($current -match "^-") {
        $detail = New-Object -TypeName PSObject
        $detail | Add-Member -Name 'Name' -MemberType Noteproperty -Value $tmp.Name
        $detail | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $detail | Add-Member -Name 'Added' -MemberType Noteproperty -Value ''
        $detail | Add-Member -Name 'Removed' -MemberType Noteproperty -Value $current.Substring(1)
        $details += $detail
    }
    elseif ($current -match "^\+") {
        $detail = New-Object -TypeName PSObject
        $detail | Add-Member -Name 'Name' -MemberType Noteproperty -Value $tmp.Name
        $detail | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $detail | Add-Member -Name 'Added' -MemberType Noteproperty -Value $current.Substring(1)
        $detail | Add-Member -Name 'Removed' -MemberType Noteproperty -Value ''
        $details += $detail
    }
}
$overview += $tmp

if ($overview.Count -eq 0) {
    Write-Output "No diff for $element"
}
else {
    if ($verbose -eq "verbose") {
        Write-Output $details
        exit 1
    }
    else {
        Write-Output $overview
        exit 1
    }
}