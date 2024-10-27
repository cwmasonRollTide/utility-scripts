$modules = @( # Keep the list of modules to be published here because it is easier to maintain and update
    "Open-File", 
    "Save-File", 
    "Compare-Strings", 
    "Get-LargeTextInput",
    "Search-ExcelContent",
    "Search-ExcelFileWithUI"
) 
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
foreach ($module in $modules) {
    Publish-Module `
        -Path "$scriptDir/$module" `
        -NuGetApiKey $env:NUGET_KEY `
        -Force
}
<<<<<<< HEAD
=======







>>>>>>> 863ccec85f4b03940c0cfe8027a06c70fa3cddf0
