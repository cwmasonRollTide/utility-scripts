. "../Shared/Save-File.ps1"
. "../Shared/Open-File.ps1"
. "../Shared/Get-LargeTextInput.ps1"
. "../Shared/Compare-Strings.ps1"
. "./Find-ExcelContent.ps1"
Import-Module ImportExcel
Add-Type -AssemblyName System.Windows.Forms

function Search-ExcelFile {
    <#
        .SYNOPSIS
            Searches for similar strings in an excel file that fit within a user-defined tolerance. 
            Can return the whole row of data for each match found or just the specified column's value.

        .DESCRIPTION
            Prompts the user to select an excel file, enter a search value, a column name, and a tolerance level.
            Prompts the user to return whole row or just the specified column's value results.
            Searches for strings that are similar to the provided search value within the specified tolerance.
            Results can be returned for the whole row or just the specified column.
            This version just runs on the console itself

        .EXAMPLE
            Search-ExcelFile
            This will execute the function and prompt for necessary input.
    #>
    [CmdletBinding()]
    Param()

    $initialDirectory = $PWD.Path 
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = $env:USERPROFILE 
    }
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    }

    $selectedFile = Open-File `
        -Title "Select the Input Excel File" `
        -InitialDirectory $initialDirectory `
        -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" 

    $searchVal = Get-ValidatedStringInput `
        -Prompt "Please enter the value you are searching for" `
        -Pattern '^[\w\s\-.,;:!?@#$%^&*()_+=\[\]{}|\\/<>~`"'']+$' `
        -ErrorMessage "Invalid input. Please enter a valid search value."
    if (-not $searchVal) { return }

    $columnName = Get-ValidatedStringInput `
        -Prompt "Enter the column name that contains the value you are searching for" `
        -Pattern '^[a-zA-Z0-9_]+$' `
        -ErrorMessage "Invalid input. Please enter a valid column name."
    if (-not $columnName) { return }

    $tolerance = Get-ToleranceInput
    $returnWholeRow = Get-YesNoInput-Bool "Do you want to return the whole row when we find matches within the tolerance you set? (y/n)"

    try {
        Write-Host "Searching file. This may take a while for large datasets..."
        $matchingStringsResults = Find-ExcelContent `
            -SelectedFile $selectedFile `
            -SearchVal $searchVal `
            -ColumnName $columnName `
            -Tolerance $tolerance `
            -ReturnWholeRow $returnWholeRow 

        $resultCount = $matchingStringsResults.Count
        Write-Host "Found $resultCount matching results."

        if ($resultCount -gt 0) {
            $saveResults = Get-YesNoInput-Bool "Do you want to save the results? (y/n)"
            if ($saveResults) {
                $savedFilePath = Save-File `
                    -Content $matchingStringsResults `
                    -Title "Save the Results File" `
                    -InitialDirectory $initialDirectory `
                    -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" 
                if ($savedFilePath) {
                    Write-Host "Results saved to: $savedFilePath"
                }
            }
        }
    }
    catch {
        Write-Error "An error occurred while searching the file: $_"
    }

    Read-Host -Prompt "Press Enter to exit"
}

## Helper Functions

function Get-ValidatedStringInput {
    param (
        [string]$prompt,
        [string]$pattern,
        [string]$errorMessage
    )
    $input = Read-Host $prompt
    if (-not $input -is [string]) {
        $input = $input.ToString()
    }
    if ($input -notMatch $pattern) {
        Write-Host $errorMessage
        return $null
    }
    return $input
}

function Get-ToleranceInput {
    $tolerance = Read-Host "Enter the number of characters the string can be off by to still be returned in the search"
    while ($tolerance -notmatch '^[0-9]$' -or [int]$tolerance -gt 9) {
        Write-Host "Invalid input. Please enter a number between 0 and 9."
        $tolerance = Read-Host "Enter the number of characters the string can be off by to still be returned in the search"
    }
    return [int]$tolerance
}

function Get-YesNoInput-Bool {
    <#
        Prompts the user for a yes or no input and returns a boolean value.

        .PARAMETER prompt
            The message to display to the user when prompting for input.

        .EXAMPLE
            Get-YesNoInput "Do you want to continue? (y/n)"
            This example prompts the user with the message "Do you want to continue? (y/n)" and returns a boolean value based on the user's input.

        .OUTPUTS
            System.Boolean
            Returns $true if the user enters 'y' or 'Y', and $false if the user enters 'n' or 'N'.
    #>
    param (
        [string]$prompt
    )
    $input = Read-Host $prompt
    while ($input -notmatch '^[ynYN]$') {
        Write-Host "Invalid input. Please enter y or n."
        $input = Read-Host $prompt
    }
    return $input -eq 'y' -or $input -eq 'Y'
}

Search-ExcelFile



