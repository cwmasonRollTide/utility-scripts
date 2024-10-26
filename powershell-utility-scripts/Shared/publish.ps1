$modules = @("Open-File", "Save-File", "Get-LargeTextInput", "Compare-Strings", "Search-ExcelContent")
foreach ($module in $modules) {
    Publish-Module -Path "./$module" NuGetApiKey $env:NUGET_KEY -Force
}