foreach ($file in (Get-ChildItem -Path "./Shared" -Filter "*.psd1" -Recurse)) {
    New-ModuleManifest -Path $file.FullName
}

