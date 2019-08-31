# Parameters
param(
    [string]$element,
    [string]$platform,
    [string]$verbose
)

#Init variables
[array]$overview = @()
[string]$path = "/var/log/jenkins/configuration-drift/"
[string]$referenceBranch = "remotes/origin/$platform-reference"
[string]$trimSize = 14 + $element.Length
[string]$log = ""
[array]$lines

# Set folder and files
If (!(Test-Path "$path")) {
    New-Item -ItemType Directory -Force -Path "diff" | Out-Null
}

# Get modification from previous steps
git add --all "export/$element"

$lines = Invoke-Expression -Command "git diff --cached $referenceBranch -- 'export/$element/*.json'"
   
# Loop on each lines 
for ($i = 0; $i -lt $lines.Count; $i++) {
    # Get value from each lines
    Switch -Regex ($lines[$i]) { 
        # Checking diff on another file (added/removed/updated)
        ’^diff --git’ { 
            $overview += $tmp
            $tmp = [PSCustomObject]@{
                Name        = ''
                Environment = $platform
                Type        = $element.Substring(4)
                Status      = ''
                Detail      = @()
            }
            break
        } 
        # The file has been removed !
        ’^deleted file mode [0-9].*’ {
            $tmp.Status = "Deleted"
            break
        }
        # The file has been added !
        ’^new file mode [0-9].*’ {
            $tmp.Status = "Added"
            break
        }
        # The file has been updated !
        ’^index [0-9a-z].*..[0-9a-z].* [0-9a-z].*’ {
            $tmp.Status = "Updated"
            break
        } 
        # We can get the file name
        ’^(---|\+\+\+)(?! \/dev\/null) ’ {
            $tmp.Name = $lines[$i].Substring($trimSize).trim().Replace('"', "")
            break
        } 
        # No need to get those lines on the detail
        ’^index|^@@|^(---|\+\+\+)’ {
            break
        }
        # Any other lines. 
        ’^(\+|-).*’ {
            if($tmp.Status -eq "Updated") {
                $tmp.Detail += $lines[$i]
            } else {
                $tmp.Detail = ""
            }
            break
        }   
    }
}

# Add the last cached value
$overview += $tmp

for ($i = 1; $i -lt $overview.Count; $i++) {
    $env = $overview[$i].Environment
    $name = $overview[$i].Name
    $type = $overview[$i].Type
    $status = $overview[$i].Status
    $detail = $overview[$i].Detail
    $log += "`n"+ "[ENV]$env[/ENV][NAME]$name[/NAME][TYPE]$type[/TYPE][STATE]$status[/STATE][DETAIL]$detail[/DETAIL]"
}

$log | Out-String -Width 4096 | Out-File /var/log/jenkins/configuration-drift/$platform-$element.log

if ($overview.count -eq 1) {
    Write-Output "No diff for $element"
    exit 0
} else {
    $overview | Format-Table | Out-String -Width 4096 | Write-Output
    exit 9
}