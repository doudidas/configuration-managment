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
    Remove-Item $folderPath/*
}


foreach ($element in $elements) {
    if (Get-Member -inputobject $element -name "Name" -Membertype Properties) {
        $pathToYamlFile = $folderPath + "/" + $element.Name + ".yaml"
        $element | ConvertTo-Yaml | Out-File -FilePath $pathToYamlFile
    }
    elseif (Get-Member -inputobject $element -name "ID" -Membertype Properties) {
        $pathToYamlFile = $folderPath + "/" + $element.Name + ".yaml"
        $element | ConvertTo-Yaml | Out-File -FilePath $pathToYamlFile    
    }
}

python3 ./sortYamlFiles.py $folderPath
