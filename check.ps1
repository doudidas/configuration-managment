# Parameters
param(
    [string]$element,
    [string]$platform,
    [string]$path,
    [string]$verbose
)
try {
    #Init variables
    [array]$overview         = @()
    [array]$details          = @()
    [string]$path            = "/var/log/jenkins/configuration-drift/"
    [string]$cachedKey       = ""
    [string]$cachedType      = ""
    [string]$referenceBranch = "remotes/origin/$platform-reference"
    [string]$trimSize        = 14 + $element.Length
    # Set folder and files
    If (!(Test-Path "$path")) { New-Item -ItemType Directory -Force -Path "diff" | Out-Null}
    # If (Test-Path "$path/$platform-$element.log") { Remove-Item -Path "$path/$platform-$element.log" | Out-Null}

    #Get all diffs
    git add --all "export/$element"
    Write-Output "git diff --cached $referenceBranch -- 'export/$element/*.json'"
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
        elseif ($lines[$i] -match '(^\-|^\+)\s*".*') {
            $status = @("Added","Removed")[$lines[$i][0] -eq "-"]
            $m      = ($lines[$i].Substring(1) | select-string '(".*?")|([a-zA-Z0-9{}[\]].*\,*)' -allmatches).matches
            $key    = $m[0].Value.trim() -replace '\"', ""
            $value  = $m[1].Value -replace '"', "" -replace ",",""
            if($key -eq "key" -and $cachedKey -eq "") {
                $cachedKey = $value
            }  elseif($key -eq "type" -and $cachedType -eq "") {
                $cachedType = $value
            } else{
                if($key -eq "value" -and $value -notin "{", "[") {
                    if($cachedKey -ne ''){
                        $key = $cachedKey
                        $value = [PSCustomObject]@{
                            type= $cachedType
                            value= $value
                        }
                    } else {
                        $value = $value
                    }
                    $cachedKey = ""
                    $cachedType = ""
                }
                $detail = [PSCustomObject]@{
                    Environment = $platform    
                    Name        = $tmp.Name
                    Type        = $element.Substring(4)
                    Key         = $key
                    Status      = $status
                    Value       = $value
                }
                if($detail.Value -notin "[", "{", ""){
                    $details += $detail
                }
            }
        }
    }

    $overview += $tmp

    $details | ForEach-Object {
        Write-Output -InputObject $_
        $env = $_.Environment
        $name = $_.Name
        $type = $_.Type
        $key  =  @($_.Key,"Unkown")[$_.Key -eq ""]
        $status = $_.Status
        $value = $_.Value
        $value = "[ENV]$env[/ENV][NAME]$name[/NAME][TYPE]$type[/TYPE][KEY]$key[/KEY][STATE]$status[/STATE][VALUE]$value[/VALUE]"
        Add-Content -Encoding utf8 -Path "$path/$platform-$element.log" -Value $value
    }

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
    $e = $_.Exception
    $line = $_.InvocationInfo.ScriptLineNumber
    Write-Host -ForegroundColor Red "caught exception: $e at $line"
    exit 9
}
