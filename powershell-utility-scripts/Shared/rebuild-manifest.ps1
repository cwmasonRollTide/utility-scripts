foreach ($file in (Get-ChildItem -Path "./Shared" -Filter "*.psd1" -Recurse)) {
    New-ModuleManifest -Path $file.FullName
}
<<<<<<< HEAD
=======




>>>>>>> 3ca2d7a2a5152cb9a8fbe288bc0dbabb6be5c47c
