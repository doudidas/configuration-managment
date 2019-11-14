# Parameters
param(
    [string]$cmd,
    [string]$verbose
)

# Connect to the source vRA instance
Get-Content .cached_session.json | ConvertFrom-Json | Set-Variable vRAConnection

Write-Output $cmd

$elements = Invoke-Expression $cmd


$folderPath    = "./export/$cmd"
$oldFolderPath = "./export_old/$cmd/" 

If (!(Test-Path $folderPath)) {
    New-Item -ItemType Directory -Force -Path $folderPath
} 

If (Test-Path $oldFolderPath) {
    Remove-Item -Recurse $oldFolderPath
}

Copy-Item -Recurse $folderPath $oldFolderPath


foreach ($element in $elements) {
    if (Get-Member -inputobject $element -name "Name" -Membertype Properties) {
        $pathToYamlFile = $folderPath + "/" + $element.Name + ".yaml"
        $element | ConvertTo-Yaml | Out-File -FilePath $pathToYamlFile
    }
    elseif (Get-Member -inputobject $element -name "ID" -Membertype Properties) {
        $pathToYamlFile = $folderPath + "/" + $element.Name + ".yaml"
        $element | ConvertTo-Yaml | Out-File -FilePath $pathToYamlFile    
    }
    $p = $cmd + ": " + $element.Name
    Write-output $p
}

python3 ./sortYamlFiles.py $folderPath