# Parameters
param(
    [string]$target
)

# Get sessions informations from json file
[PSCustomObject]$sessions = GET-Content "sessions.json" | ConvertFrom-Json
Write-Output $sessions.$target
$s = $sessions.$target

# Init credantials Obj
$secpasswd = ConvertTo-SecureString $s.password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($s.username, $secpasswd)

# Connect to the source vRA instance
$obj = Connect-vRAServer -Server $s.url -Tenant $s.tenant -Credential $cred  -IgnoreCertRequirements 

Write-Output $obj

ConvertTo-Json -InputObject $obj | Out-File ".cached_session.json"