# Parameters
param(
    [string]$cmd,
    [string]$verbose
)

# Connect to the source vRA instance
Get-Content .cached_session.json | ConvertFrom-Json | Set-Variable vRAConnection

Write-Output $cmd

$elements = Invoke-Expression $cmd
if ($verbose -ne 'silent') {
    Write-Output $elements
}


$folderPath = "export/$cmd"
 
If (!(Test-Path $folderPath)) {
    New-Item -ItemType Directory -Force -Path $folderPath
}
else {
    Remove-Item $folderPath/*.json
}


foreach ($element in $elements) {
    if (Get-Member -inputobject $element -name "Name" -Membertype Properties) {
        # $pathToJsonFile = $folderPath + "/" + $element.Name + ".json"
        $pathToYamlFile = $folderPath + "/" + $element.Name + ".yaml"
        # ConvertTo-json -InputObject $element -Depth 50 | Out-File -FilePath $pathToJsonFile
        ConvertTo-Yaml $element | Out-File -FilePath $pathToYamlFile
    }
    elseif (Get-Member -inputobject $element -name "ID" -Membertype Properties) {
        # $pathToJsonFile = $folderPath + "/" + $element.ID + ".json"
        $pathToYamlFile = $folderPath + "/" + $element.Name + ".yaml"
        # ConvertTo-Json -InputObject $element -Depth 50 | Out-File -FilePath $pathToJsonFile
        ConvertTo-Yaml $element | Out-File -FilePath $pathToYamlFile
    
    }
}
