# Parameters
param(
    [string]$element,
    [string]$platform,
    [string]$verbose
)
If (!(test-path "diff")) {
    New-Item -ItemType Directory -Force -Path "diff"
}
If (test-path "diff/$element.log") {
    Remove-Item -Path "diff/$element.log"
}

New-Item -Path "diff/$element.log" -ItemType File

$referenceBranch = "remotes/origin/$platform-reference"
git add --all "export/$element"

[array]$lines = git diff --cached $referenceBranch -- "export/$element/*.json" 
$overview = @()
$details = @()
$trimSize = 14 + $element.Length 
$tmp = New-Object -TypeName PSObject
for ($i = 0; $i -lt $lines.Count; $i++) {
    $current = $lines[$i]
    if ($current -match "^diff --git") {
        $overview += $tmp
        $status = ''
        $tmp = New-Object -TypeName PSObject
        $tmp | Add-Member -Name 'Name' -MemberType Noteproperty -Value ''
        $tmp | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $tmp | Add-Member -Name 'Added' -MemberType Noteproperty -Value ''
        $tmp | Add-Member -Name 'Updated' -MemberType Noteproperty -Value ''
        $tmp | Add-Member -Name 'Deleted' -MemberType Noteproperty -Value ''

    }
    elseif ($current -match "^deleted file mode [0-9].*") {
        $status = "Deleted"
        $tmp.Deleted = '   x'
    }
    elseif ($current -match "^new file mode [0-9].*") {
        $status = "Added"
        $tmp.Added = '  x'
    }
    elseif ($current -match "^index [0-9a-z].*..[0-9a-z].* [0-9a-z].*") {
        $status = "Updated"
        $tmp.Updated = '   x'
    }
    elseif ($current -match "^(---|\+\+\+)") {
        if ($current -notmatch "(---|\+\+\+) /dev/null") {
            $tmp.Name = $current.Substring($trimSize).trim().Replace('"', "")
        }
    }
    elseif ($current -match "^-") {
        $detail = New-Object -TypeName PSObject
        $detail | Add-Member -Name 'Name' -MemberType Noteproperty -Value $tmp.Name
        $detail | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $detail | Add-Member -Name 'Status' -MemberType Noteproperty -Value $status
        $detail | Add-Member -Name 'Added' -MemberType Noteproperty -Value ''
        $detail | Add-Member -Name 'Removed' -MemberType Noteproperty -Value $current.Substring(1)
        $details += $detail
    }
    elseif ($current -match "^\+") {
        $detail = New-Object -TypeName PSObject
        $detail | Add-Member -Name 'Name' -MemberType Noteproperty -Value $tmp.Name
        $detail | Add-Member -Name 'Type' -MemberType Noteproperty -Value $element.Substring(4)
        $detail | Add-Member -Name 'Status' -MemberType Noteproperty -Value $status
        $detail | Add-Member -Name 'Added' -MemberType Noteproperty -Value $current.Substring(1)
        $detail | Add-Member -Name 'Removed' -MemberType Noteproperty -Value ''
        $details += $detail
    }
}

$overview += $tmp

$previous = ""
$details | ForEach-Object {
    $name = $_.Name
    $status = $_.Status 
    if($name -eq $previous) {
        if ($status -eq "Added") {
            $a = $_.Added
            $added += "[ADD]$a[/ADD]"
        } elseif ($status -eq "Deleted") {
            $d = $_.Removed
            $deleted += "[DEL]$d[/DEL]"
        } 
    } else  {
    $type = $_.Type

    write-output $_.Added.Trim()
    $value = "[ENV]$platform[/ENV][OBJ]$name[/OBJ][TYPE]$type[/TYPE][STATE]$status[/STATE]$added$deleted"
    Add-Content -Path "diff/$element.log" -Value $value
    $status = ""
    $added = ""
    $deleted = ""
    }
    $previous = $name
}


if ($overview.Count -eq 0) {
    Write-Output "No diff for $element"
}
else {
    if ($verbose -eq "verbose") {
        $details | Format-Table | Out-String -Width 4096 | Write-Output
    }
    else {
        $overview | Format-Table | Out-String -Width 4096 | Write-Output
    }
}