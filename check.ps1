    $cmd = "git diff --cached $referenceBranch -- 'export/$element/*.json'"
    Write-Output $cmd
    [array]$lines = Invoke-Expression -Command $cmd
    $details | Format-Table | Out-String -Width 4096 | Out-File /tmp/$platform-$element.txt