# Parameters
param(
    [string]$element,
    [string]$platform,
    [string]$path,
    [string]$verbose
)
try {
    #Init
    [array]$overview = @()
    [array]$details = @()
    $referenceBranch = "remotes/origin/$platform-reference"
    $trimSize = 14 + $element.Length

    # Set folder and files
    If (!(Test-Path "$path")) { New-Item -ItemType Directory -Force -Path "diff" | Out-Null}
    If (Test-Path "$path/$platform-$element.log") { Remove-Item -Path "$path/$platform-$element.log" | Out-Null}

    #Get all diffs
    git add --all "export/$element"
    [array]$lines = git diff --cached $referenceBranch -- "export/$element/*.json" 

    for ($i = 0; $i -lt $lines.Count; $i++) {
        $lines[$i] = $lines[$i]
        if ($lines[$i] -match "^diff --git") {
            $overview += $tmp
            $tmp = [PSCustomObject]@{
                Name    = ''
                Type    = $element.Substring(4)
                Added   = ''
                Updated = ''
                Deleted = ''
            }
        }
        elseif ($lines[$i] -match "^deleted file mode [0-9].*") {
            $tmp.Deleted = '   x'
        }
        elseif ($lines[$i] -match "^new file mode [0-9].*") {
            $tmp.Added = '  x'
        }
        elseif ($lines[$i] -match "^index [0-9a-z].*..[0-9a-z].* [0-9a-z].*") {
            $tmp.Updated = '   x'
        }
        elseif ($lines[$i] -match "^(---|\+\+\+)") {
            if ($lines[$i] -notmatch "(---|\+\+\+) /dev/null") {
                $tmp.Name = $lines[$i].Substring($trimSize).trim().Replace('"', "")
            }
        }
        elseif ($lines[$i] -match "^-|^\+") {
            write-output $lines[$i]
            $m      = ($lines[$i].Substring(1) | select-string '(".*?")|([[:alnum:]].*\,*)' -allmatches).matches
            $detail = [PSCustomObject]@{
                Environment = $platform    
                Name        = $tmp.Name
                Type        = $element.Substring(4)
                Status      = @("Removed","Added")[$lines[$i][0] -eq "-"]
                Key         = $m[0] -replace '"', ""
                Value       = $m[1] -replace '"', "" -replace ",",""
              }
            $details += $detail
        }
    }

    $overview += $tmp

    # $previous = ""
    # $details | ForEach-Object {
    #     $name = $_.Name
    #     $status = $_.Status 
    #     if ($name -eq $previous) {
    #         if ($status -eq "Added") {
    #             $a = $_.Added
    #             $added += "[ADD]$a[/ADD]"
    #         }
    #         elseif ($status -eq "Deleted") {
    #             Write-Output $d
    #             $deleted += "[DEL]$d[/DEL]"
    #         } 
    #     }
    #     else {
    #         $type = $_.Type
    #         $value = "[ENV]$platform[/ENV][OBJ]$name[/OBJ][TYPE]$type[/TYPE][STATE]$status[/STATE]$added$deleted"
    #         Add-Content -Encoding utf8 -Path "$path/$platform-$element.log" -Value $value
    #         $status = ""
    #         $added = ""
    #         $deleted = ""
    #     }
    #     $previous = $name
    # }

    # sort
    $details = $details | Sort-Object -Property Name,Key,Status
    ConvertTo-Json -InputObject $details | Add-Content -Encoding utf8 -Path "$path/$platform-$element.log"
    if ($details.count -eq 0) {
        Write-Output "No diff for $element"
        exit 0
    }
    else {
        if ($verbose -eq "verbose") {
            $details | Format-Table | Out-String -Width 4096 | Write-Output
            exit 9
        }
        else {
            $overview | Format-Table | Out-String -Width 4096 | Write-Output
            exit 9
        }
        exit 0
    }
}
catch {
    Write-Host $_
    exit 9
}
