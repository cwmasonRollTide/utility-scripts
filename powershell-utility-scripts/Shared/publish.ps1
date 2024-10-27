$modules = @(
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
