# Parameters
param(
    [string]$element,
    [string]$source,
    [string]$destination
)

#Init variables
[array]$overview = @()
[string]$path = "/var/log/jenkins/configuration-drift/"
[string]$trimSize = 14 + $element.Length
[string]$log = ""
[array]$lines

# Set folder and files
If (!(Test-Path "$path")) {
    New-Item -ItemType Directory -Force -Path "diff" | Out-Null
}

# Get modification from previous steps
git add --all "export/$element"

# Git diff command
$lines = Invoke-Expression -Command "git diff $source $destination -- 'export/$element/*.yaml'"
   
$sourceBranch      = $source.split("/")[$source.split("/").Count - 1]
$destinationBranch = $destination.split("/")[$destination.split("/").Count - 1]

# Loop on each lines 
for ($i = 0; $i -lt $lines.Count; $i++) {
    # Get value from each lines
    Switch -Regex ($lines[$i]) { 
        # Checking diff on another file (added/removed/updated)
        ’^diff --git’ { 
            $overview += $tmp
	    $element.split("-")[1]	

            $tmp = [PSCustomObject]@{
                Name        = ''
                Source      = $sourceBranch
                Destination = $destinationBranch
                Product     = $element.split("-")[1].substring('0','3')
                Type        = $element.split("-")[1].substring('3')
                Status      = ''
                Detail      = @()
            }
            break
        } 
        # The file has been removed !
        ’^deleted file mode [0-9].*’ {
            $tmp.Status = "Added"
            break
        }
        # The file has been added !
        ’^new file mode [0-9].*’ {
            $tmp.Status = "Deleted"
            break
        }
        # The file has been updated ?
        ’^index [0-9a-z].*..[0-9a-z].* [0-9a-z].*’ {
            $tmp.Status = "Updated"
            break
        }
        # We can get the file name
        ’^(---|\+\+\+)(?! \/dev\/null) ’ {
            $tmp.Name = $lines[$i].Substring($trimSize).trim().Replace('"', "")
            break
        } 
        #No need to get those lines on the detail
        ’^index|^@@|^(---|\+\+\+)’ {
         break
        }
        # Any other lines. 
        ’.*’ {
            $tmp.Detail += $lines[$i] + "|"
            break
        }  
    }
}

# Add the last cached value
$overview += $tmp

for ($i = 1; $i -lt $overview.Count; $i++) {
    $source      = $overview[$i].Source
    $destination = $overview[$i].Destination
    $name        = $overview[$i].Name
    $type        = $overview[$i].Type
    $product     = $overview[$i].Product
    $detail      = $overview[$i].Detail
    
    # Remove false positive
    if ($status -eq "Updated") {
        if ($detail -eq "") {
	        sizeA = (Get-Item "export/$element/$tmp.Name").length
        	sizeB = (Get-Item "export_old/$element/$tmp.Name").length
        	if ($sizeA -eq $sizeB) {
			$overview[$i].Status = ""
        	}
	    }
    }

    $status = $overview[$i].Status

    $log += "`n"+ "[SOURCE]$source[/SOURCE][DESTINATION]$destination[/DESTINATION][NAME]$name[/NAME][TYPE]$type[/TYPE][PRODUCT]$product[/PRODUCT][STATE]$status[/STATE][DETAIL]$detail[/DETAIL]"
}

$log | Out-String -Width 4096 | Out-File /var/log/jenkins/configuration-drift/$sourceBranch-$destinationBranch-$element.log

if ($overview.count -eq 1) {
    Write-Output "No diff for $element between $source and $destination"
    exit 0
} else {
    $overview | Format-Table | Out-String -Width 4096 | Write-Output
    exit 9
}
