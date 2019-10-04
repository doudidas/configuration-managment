# Parameters
param(
    [string]$target
)

# Get sessions informations from json file
[PSCustomObject]$sessions = Get-Content "sessions.json" | ConvertFrom-Json
Write-Output $sessions.$target
$s = $sessions.$target

# Init credantials Obj
$secpasswd = ConvertTo-SecureString $s.password -AsPlainText -Force
$cred = New-Object System.Management.Automation.PSCredential ($s.username, $secpasswd)

switch ($s.serverType) {
    vra { 
        # Connect to the source vRA instance
        $obj = Connect-vRAServer -Server $s.url -Tenant $s.tenant -Credential $cred  -IgnoreCertRequirements 
    }
    vcd {
        # Connect to the source vCD instance
        $obj = Connect-CIServer -Server $s.url -Credential $cred 
    }
}

Write-Output $obj

ConvertTo-Json -InputObject $obj | Out-File ".cached_session.json"