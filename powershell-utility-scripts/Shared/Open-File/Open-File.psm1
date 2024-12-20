function Open-File {
    param (
        [string]$FilePath
    )

    if (-Not (Test-Path $FilePath)) {
        throw "File not found: $FilePath"
    }

    $content = Get-Content -Path $FilePath
    return $content
}