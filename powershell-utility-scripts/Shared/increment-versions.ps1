$baseDir = "."
$lastCommitHash = (git rev-parse HEAD~1)

Get-ChildItem -Path $baseDir -Include *.psd1 -Recurse | ForEach-Object {
    $filePath = $_.FullName
    $fileContent = Get-Content $filePath -Raw

    $lastFileContent = (git show "${lastCommitHash}:${filePath}")

    if ($lastFileContent -ne $fileContent) {
        $updatedContent = $fileContent -replace '(ModuleVersion\s*=\s*[''])(\d+)\.(\d+)\.(\d+)([''])', {
            $major = [int]$matches[2]
            $minor = [int]$matches[3]
            $build = [int]$matches[4]
            $newVersion = "{0}.{1}.{2}" -f $major, $minor, ($build + 1)
            return '{0}{1}{2}' -f $matches[1], $newVersion, $matches[5]
        }
        
        Set-Content $filePath $updatedContent
        # Stage the updated file
        git add $filePath

        # Commit the change
        git commit -m "Incremented ModuleVersion in $filePath"
        Write-Host "Incremented ModuleVersion in $filePath"
    }
}