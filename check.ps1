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
    Write-Output "git diff --cached $referenceBranch -- 'export/$element/*.json'"

        $lines[$i] = $lines[$i]
        if ($lines[$i] -match "^diff --git") {
            $tmp = [PSCustomObject]@{
                Name    = ''
                Type    = $element.Substring(4)
                Added   = ''
                Updated = ''
                Deleted = ''
            }
        elseif ($lines[$i] -match "^deleted file mode [0-9].*") {
        elseif ($lines[$i] -match "^new file mode [0-9].*") {
        elseif ($lines[$i] -match "^index [0-9a-z].*..[0-9a-z].* [0-9a-z].*") {
        elseif ($lines[$i] -match "^(---|\+\+\+)") {
            if ($lines[$i] -notmatch "(---|\+\+\+) /dev/null") {
                $tmp.Name = $lines[$i].Substring($trimSize).trim().Replace('"', "")
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
        $env = $_.Environment
        $type = $_.Type
        $key  =  @($_.Key,"Unkown")[$_.Key -eq ""]
        $status = $_.Status
        $value = $_.Value
        $value = "[ENV]$env[/ENV][NAME]$name[/NAME][TYPE]$type[/TYPE][KEY]$key[/KEY][STATE]$status[/STATE][VALUE]$value[/VALUE]"
        Add-Content -Encoding utf8 -Path "$path/$platform-$element.log" -Value $value
    $e = $_.Exception
    $line = $_.InvocationInfo.ScriptLineNumber
    Write-Host -ForegroundColor Red "caught exception: $e at $line"