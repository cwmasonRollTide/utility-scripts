$modules = @("Open-File", "Save-File", "Get-LargeTextInput", "Compare-Strings", "Search-ExcelContent") 
$scriptDir = Split-Path $script:MyInvocation.MyCommand.Path
foreach ($module in $modules) {
    Publish-Module -Path "$scriptDir/$module" -NuGetApiKey $env:NUGET_KEY -Force
}
