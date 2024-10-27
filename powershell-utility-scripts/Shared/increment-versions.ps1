$baseDir = "."
$lastCommitHash = (git rev-parse HEAD~1)

Get-ChildItem -Path $baseDir -Include *.ps1 -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $fileContent = Get-Content $filePath -Raw

    $lastFileContent = (git show "${lastCommitHash}:${filePath}")

    if ($lastFileContent -ne $fileContent) {
        $updatedContent = $fileContent -replace '(ModuleVersion\s*=\s*[''])([\d\.]+)([''])', {
            $version = [version]$matches[2]
            $newVersion = "{0}.{1}.{2}" -f $version.Major, $version.Minor, ($version.Build + 1)
            return '{0}{1}{2}' -f $matches[1], $newVersion, $matches[3]
        }

        Set-Content $filePath $updatedContent
        Write-Host "Incremented ModuleVersion in $filePath"
    }
}



