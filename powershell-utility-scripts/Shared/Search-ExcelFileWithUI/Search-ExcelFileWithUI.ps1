Import-Module ImportExcel
Add-Type -AssemblyName System.Windows.Forms

. "$PSScriptRoot/../Shared/Save-File/Save-File.ps1"
. "$PSScriptRoot/../Shared/Open-File/Open-File.ps1"
. "$PSScriptRoot/../Shared/Compare-Strings/Compare-Strings.ps1"
. "$PSScriptRoot/../Shared/Get-LargeTextInput/Get-LargeTextInput.ps1"
. "$PSScriptRoot/../Shared/Search-ExcelContent/Search-ExcelContent.ps1"

function Search-ExcelFileWithUI {
    <#
        .SYNOPSIS
            Searches for similar strings in an excel file that fit within a user-defined tolerance. 
            Can return the whole row of data for each match found or just the specified column's value.

        .DESCRIPTION
            Prompts the user to select an excel file, enter a search value, a column name, and a tolerance level.
            Prompts the user to return whole row or just the specified column's value results.
            Searches for strings that are similar to the provided search value within the specified tolerance.
            Results can be returned for the whole row or just the specified column.

        .EXAMPLE
            Search-ExcelFileWithUI
            This will execute the function and prompt for necessary input.

        .NOTES
            Author: Connor Mason
            Last Updated: 10/2/2024
    #>
    [CmdletBinding()]
    Param()

    $initialDirectory = Get-StartLocation
    $selectedFile = Open-File `
        -Title "Select the Input Excel File" `
        -InitialDirectory $initialDirectory `
        -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" 

    $searchVal = Get-LargeTextInput `
        -prompt "Please enter the value you are searching for (e.g., SSN, name, or other identifier)" `
        -title "Search Value" `
        -validationPattern '^\S+$' `
        -errorMessage "Invalid input. Please enter a non-empty search value without spaces."

    $columnName = Get-LargeTextInput `
        -prompt "Enter the column name that contains the value you are searching for" `
        -title "Column Name" `
        -validation '^[a-zA-Z0-9_]+$' `
        -errorMessage "Invalid input. Please enter a valid column name."

    $tolerance = Get-ToleranceInput
    $returnWholeRow = Get-YesNoInput-Bool `
        -Prompt "Do you want to return the whole row of data when we find matches within the tolerance you set?"
    
    try {
        Write-Host "Searching file. This may take a while for large datasets..."
        $matchingStringsResults = Search-ExcelContent `
            -SelectedFile $selectedFile `
            -SearchVal $searchVal `
            -ColumnName $columnName `
            -Tolerance $tolerance `
            -ReturnWholeRow $returnWholeRow

        $resultCount = $matchingStringsResults.Count
        Write-Host "Found $resultCount matching results."
        if ($resultCount -gt 0) {
            $saveResults = Get-YesNoInput-Bool -Prompt "Do you want to save the results?"
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
        Write-Error "An error occurred while searching the file: $_"#_catches the error message and displays it
    }
    [System.Windows.Forms.MessageBox]::Show("Search completed. Press OK to exit.", "Search Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

## Helper Functions

function Get-StartLocation {
    <#
        .SYNOPSIS
            Gets the initial directory for file dialogs. Starts where the .ps1 or exe is run from, then user profile, then desktop.

        .DESCRIPTION
            Gets the initial directory for file dialogs based on the current working directory, user profile, or desktop.

        .EXAMPLE
            Get-StartLocation
            This example returns the initial directory for file dialogs.
    #>
    $initialDirectory = $PWD.Path 
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = $env:USERPROFILE 
    }
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    }
    return $initialDirectory
}

function Get-ToleranceInput {
    $tolerance = Get-LargeTextInput `
        -prompt "Enter the number of characters the string can be off by to still be returned in the search" `
        -title "Tolerance" `
        -validation '^[0-9]$' `
        -errorMessage "Invalid input. Please enter a number between 0 and 9."
    
    if ($null -ne $tolerance) {
        return [int]$tolerance
    }
    return $null
}

function Get-YesNoInput-Bool {
    <#
        .SYNOPSIS
            Prompts the user for a Yes/No input and returns a boolean value.

        .DESCRIPTION
            Prompts the user with a message box to select Yes or No.
            Returns a boolean value based on the user's selection.

        .PARAMETER prompt
            The message to display in the prompt.

        .EXAMPLE
            Get-YesNoInput-Bool -prompt "Do you want to continue?"
            This example prompts the user with the message "Do you want to continue?" and returns a boolean value based on the user's selection.

        .NOTES
    #>
    param (
        [string]$prompt
    )
    $result = [System.Windows.Forms.MessageBox]::Show($prompt, "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    return ($result -eq 'Yes')
}

Search-ExcelFileWithUI





