# Parameters
param(
    [string]$cmd
)

# Connect to the source vRA instance
Get-Content .cached_session.json | ConvertFrom-Json | Set-Variable vRAConnection

Write-Output $cmd

$elements = Invoke-Expression $cmd

Write-Output $elements

$folderPath = "export/$cmd"

If (!(test-path $folderPath)) {
    New-Item -ItemType Directory -Force -Path $folderPath
} else {
    Remove-Item $folderPath/*.json
}


foreach ($element in $elements) {
    if (Get-Member -inputobject $element -name "Name" -Membertype Properties) {
        $pathToFile = $folderPath + "/" + $element.Name + ".json"
        ConvertTo-Json -InputObject $element | Out-File -FilePath $pathToFile
    }
    elseif (Get-Member -inputobject $element -name "ID" -Membertype Properties) {
        $pathToFile = $folderPath + "/" + $element.ID + ".json"
        ConvertTo-Json -InputObject $element | Out-File -FilePath $pathToFile
    }
}
