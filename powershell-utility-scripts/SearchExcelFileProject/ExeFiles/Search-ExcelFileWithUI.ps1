Import-Module ImportExcel
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Find-ExcelContent {
<#
    .SYNOPSIS
        Finds matching strings within a specified tolerance in an excel file. Either returns the entire rows or just the matching values.

    .DESCRIPTION
        The Find-ExcelContent function searches for matching strings within a specified tolerance in an excel file. 
        It compares the search value with the values in the specified column of the excel file and returns either the matching strings or the entire row.

    .PARAMETER selectedFile
        Specifies the path to the excel file. Must be excel File because it searches by column name and optionally returns the entire row.

    .PARAMETER searchVal
        Specifies the value to search for within the excel file.

    .PARAMETER columnName
        Specifies the name of the column in the excel file to search within.

    .PARAMETER tolerance
        Specifies the tolerance level for string comparison. Only strings within this tolerance level will be considered as matches.

    .PARAMETER returnWholeRow
        Boolean value specifying whether to return the entire row of data or just the matching value you're looking for

    .EXAMPLE
        Find-ExcelContent -selectedFile "C:\path\to\file.excel" -searchVal "apple" -columnName "Fruit" -tolerance 2 -returnWholeRow "y"
        This example searches for the value "apple" within the "Fruit" column of the excel file located at "C:\path\to\file.excel". It allows a tolerance of 2 characters for string comparison and returns the entire row for each matching string.

    .EXAMPLE
        Find-ExcelContent -selectedFile "C:\path\to\file.excel" -searchVal "banana" -columnName "Fruit" -tolerance 1 -returnWholeRow "n"
        This example searches for the value "banana" within the "Fruit" column of the excel file located at "C:\path\to\file.excel". It allows a tolerance of 1 character for string comparison and returns only the matching value for each match.

    .OUTPUTS
        System.Object[] | string[] 
        An array of matching strings or rows from the excel file, depending on the returnWholeRow parameter.

    .NOTES
        Author: Connor Mason
        Date:   10/2/2024

#>
    [CmdletBinding()]
    param (
        [string]$selectedFile,
        [string]$searchVal,
        [string]$columnName,
        [int]$tolerance,
        [boolean]$returnWholeRow
    )

    $isExecutable = [System.Diagnostics.Process]::GetCurrentProcess().MainModule.FileName -ne (Get-Process -Id $PID).MainModule.FileName

    function Write-ProgressConsole {
        param([string]$message)
        if ($isExecutable) { return }
        Write-Host $message
    }

    function Show-ProgressForm {
        param([int]$totalRows)
        $script:form = New-Object System.Windows.Forms.Form
        $script:form.Text = 'Searching Excel File'
        $script:form.Size = New-Object System.Drawing.Size(400,100)
        $script:form.StartPosition = 'CenterScreen'

        $script:progressBar = New-Object System.Windows.Forms.ProgressBar
        $script:progressBar.Size = New-Object System.Drawing.Size(380,20)
        $script:progressBar.Location = New-Object System.Drawing.Point(10,10)
        $script:progressBar.Style = 'Continuous'

        $script:label = New-Object System.Windows.Forms.Label
        $script:label.Location = New-Object System.Drawing.Point(10,40)
        $script:label.Size = New-Object System.Drawing.Size(380,20)
        $script:label.Text = "Initializing search..."

        $script:form.Controls.Add($script:progressBar)
        $script:form.Controls.Add($script:label)

        $script:form.Show()
        $script:form.Focus() | Out-Null
        $script:form.Refresh()
    }

    function Update-Progress {
        param([int]$current, [int]$total, [int]$matchCount)
        if ($isExecutable) {
            $percent = [int](($current / $total) * 100)
            $script:progressBar.Value = $percent
            $script:label.Text = "Searching... $percent% complete. Matches found: $matchCount"
            $script:form.Refresh()
        } else {
            Write-Progress -Activity "Searching Excel File" -Status "Progress: $([int](($current / $total) * 100))%" -PercentComplete (($current / $total) * 100)
        }
    }

    $excelData = Import-Excel -Path $selectedFile
    $totalRows = $excelData.Count
    $matchingStringsResults = @()
    $matchCount = 0

    Show-ProgressForm -totalRows $totalRows

    for ($i = 0; $i -lt $totalRows; $i++) {
        $row = $excelData[$i]
        $currentVal = $row.$columnName

        if (Compare-Strings -Str1 $searchVal -Str2 $currentVal -Tolerance $tolerance) {
            $matchCount++
            if ($returnWholeRow) {
                $matchingStringsResults += $row
            } else {
                $matchingStringsResults += [PSCustomObject]@{$columnName = $currentVal}
            }
        }

        Update-Progress -current ($i + 1) -total $totalRows -matchCount $matchCount
    }

    if ($isExecutable) {
        $script:form.Close()
        [System.Windows.Forms.MessageBox]::Show("Search complete. Total matches found: $matchCount", "Search Results", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    } else {
        Write-ProgressConsole "Search complete. Total matches found: $matchCount"
    }

    return $matchingStringsResults
}

function Compare-Strings {
    <#
       .SYNOPSIS
          Compares two strings character by character and checks if the number of differences is less than or equal to a given tolerance.
 
       .DESCRIPTION
          The Compare-Strings function takes in two strings and a tolerance value. It iterates over each character in the first string and compares it with the corresponding character in the second string. If the characters are not equal, it increments a differences counter. Finally, it checks if the total number of differences is less than or equal to the tolerance value.
 
       .PARAMETER str1
          The first string to compare.
 
       .PARAMETER str2
          The second string to compare.
 
       .PARAMETER tolerance
          The maximum number of character differences allowed between the two strings.
 
       .EXAMPLE
          Compare-Strings -str1 "hello" -str2 "helli" -tolerance 1
          Returns True because there is only one character difference between the two strings, which is less than or equal to the tolerance.
 
       .OUTPUTS
          Boolean. Returns True if the number of character differences between the two strings is less than or equal to the tolerance, otherwise False.
 
       .NOTES
          Author: Connor Mason
          Date: 10/2/2024
    #>
    [CmdletBinding()]
    Param(
       [string]$str1,
       [string]$str2,
       [int]$tolerance
    )
    $differences = 0
    $maxLength = [Math]::Max($str1.Length, $str2.Length)
    $minLength = [Math]::Min($str1.Length, $str2.Length)
 
    for ($i = 0; $i -lt $maxLength; $i++) {
       if ($i -lt $minLength) {
          if ($str1[$i] -ne $str2[$i]) {
             $differences++
          }
       } else {
          $differences++
       }
 
       if ($differences -gt $tolerance) {
          return $false
       }
    }
 
    return $differences -le $tolerance
}

function Get-LargeTextInput {
<#
    .SYNOPSIS
        Prompts the user for input in a large text box.

    .DESCRIPTION
        Displays a dialog box that prompts the user for a text input.
        The user can enter text and click OK to submit it.
        The user can also click Cancel to exit the dialog without submitting any text.

    .PARAMETER prompt
        The message to display to the user.

    .PARAMETER title
        The title of the dialog box.

    .PARAMETER defaultValue
        The default value to display in the text box.

    .PARAMETER validation
        A script block that validates the input. Should return $true if the input is valid, $false otherwise.

    .PARAMETER errorMessage
        The error message to display if the input is invalid.

    .EXAMPLE
        Get-LargeTextInput -prompt "Please enter a description of the issue" -title "Issue Description"
        This will display a dialog box with a text box for the user to enter a description of the issue.

    .NOTES
        Author: Connor Mason
        Date: 10/2/2024
#>
    param (
        [string]$prompt,
        [string]$title,
        [string]$defaultValue = "",
        [string]$validationPattern = '^\S+$',
        [string]$errorMessage = "Invalid input. Please enter a non-empty value without whitespace."
    )

    $fontFamily = "Inter, Segoe UI, Arial, Sans-Serif"

    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size(500,250)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)

    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point(10,10)
    $panel.Size = New-Object System.Drawing.Size(465,190)
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $panel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($panel)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(20,20)
    $label.Size = New-Object System.Drawing.Size(425,40)
    $label.Text = $prompt
    $label.Font = New-Object System.Drawing.Font($fontFamily, 12, [System.Drawing.FontStyle]::Regular)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $panel.Controls.Add($label)

    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(20,70)
    $textBox.Size = New-Object System.Drawing.Size(425,30)
    $textBox.Font = New-Object System.Drawing.Font($fontFamily, 12, [System.Drawing.FontStyle]::Regular)
    $textBox.Text = $defaultValue
    $panel.Controls.Add($textBox)

    $errorLabel = New-Object System.Windows.Forms.Label
    $errorLabel.Location = New-Object System.Drawing.Point(20,110)
    $errorLabel.Size = New-Object System.Drawing.Size(425,30)
    $errorLabel.ForeColor = [System.Drawing.Color]::Red
    $errorLabel.Font = New-Object System.Drawing.Font($fontFamily, 10, [System.Drawing.FontStyle]::Regular)
    $panel.Controls.Add($errorLabel)

    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Location = New-Object System.Drawing.Point(295,150)
    $okButton.Size = New-Object System.Drawing.Size(75,30)
    $okButton.Text = "OK"
    $okButton.Font = New-Object System.Drawing.Font($fontFamily, 10, [System.Drawing.FontStyle]::Regular)
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $okButton.BackColor = [System.Drawing.Color]::FromArgb(0,120,215)
    $okButton.ForeColor = [System.Drawing.Color]::White
    $form.AcceptButton = $okButton
    $panel.Controls.Add($okButton)

    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Location = New-Object System.Drawing.Point(380,150)
    $cancelButton.Size = New-Object System.Drawing.Size(75,30)
    $cancelButton.Text = "Cancel"
    $cancelButton.Font = New-Object System.Drawing.Font($fontFamily, 10, [System.Drawing.FontStyle]::Regular)
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $cancelButton.BackColor = [System.Drawing.Color]::White
    $cancelButton.ForeColor = [System.Drawing.Color]::Black
    $form.CancelButton = $cancelButton
    $panel.Controls.Add($cancelButton)

    $form.Add_Shown({$textBox.Select()})

    do {
        $result = $form.ShowDialog()
        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            $inputValue = $textBox.Text
            if ($inputValue -match $validationPattern) {
                return $inputValue
            } else {
                $errorLabel.Text = $errorMessage
            }
        } elseif ($result -eq [System.Windows.Forms.DialogResult]::Cancel) {
            return $null
        }
    } while ($true)
}

function Open-File {
    <#
        .SYNOPSIS
            Allows the user to Open a file for processing.

        .DESCRIPTION
            Opens a file dialog that lets the user Open a file. The file type can be specified; defaults to all file types.

        .PARAMETER fileType
            The file extension to filter by in the file dialog. Default is "All files (*.*)".

        .PARAMETER title
            The title of the file dialog. Default is "Open a File".

        .PARAMETER initialDirectory
            The initial directory to display in the file dialog. Default is the directory of the script.

        .EXAMPLE
            Open-File -fileType "*.txt"
            Opens a dialog allowing only text files to be selected.

        .EXAMPLE
            Open-File
            Opens a dialog allowing any file type to be selected.

        .OUTPUTS 
            String
            The full path of the selected file. If canceled, exits the script.
        
        .NOTES
            Author: Connor Mason
            Date: 10/2/2024
    #>
    [CmdletBinding()]
    Param(
        [string]$fileTypeFilter = "All files (*.*)",
        [string]$title = "Select a File",
        [string]$initialDirectory = ""
    )
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $openFileDialog.title = $title
    $openFileDialog.Filter = $fileTypeFilter
    $openFileDialog.initialDirectory = $initialDirectory
    $result = $openFileDialog.ShowDialog()
    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $selectedFile = $openFileDialog.FileName
        return $selectedFile
    } else {
        Write-Host "No file was selected."
        exit
    }
}

$exportMethods = @{
    ".xlsx" = @{
        ValidTypes = @("Object[]", "PSCustomObject[]")
        ExportFunction = { param($content, $FilePath) 
            $content | Export-Excel -Path $FilePath -Show -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow 
        }
    }
    ".xls" = @{
        ValidTypes = @("Object[]", "PSCustomObject[]")
        ExportFunction = { param($content, $FilePath) 
            $content | Export-Excel -Path $FilePath -Show -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow 
        }
    }
    ".csv" = @{
        ValidTypes = @("Object[]", "PSCustomObject[]")
        ExportFunction = { param($content, $FilePath) 
            $content | Export-Csv -Path $FilePath -NoTypeInformation 
        }
    }
    ".json" = @{
        ValidTypes = @("Object[]", "PSCustomObject[]", "Hashtable", "PSObject")
        ExportFunction = { param($content, $FilePath) 
            $content | ConvertTo-Json -Depth 100 | Set-Content -Path $FilePath 
        }
    }
    ".xml" = @{
        ValidTypes = @("XmlDocument", "Object[]", "PSCustomObject[]")
        ExportFunction = { param($content, $FilePath) 
            if ($content -is [System.Xml.XmlDocument]) {
                $content.Save($FilePath)
            } else {
                $content | Export-Clixml -Path $FilePath
            }
        }
    }
    ".txt" = @{
        ValidTypes = @("String", "Object[]", "PSCustomObject[]")
        ExportFunction = { param($content, $FilePath) 
            if ($content -is [string]) {
                [System.IO.File]::WriteAllText($FilePath, $content)
            } else {
                $content | Out-File -FilePath $FilePath
            }
        }
    }
}

function Save-File {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [object]$content,
        [string]$title = "Save File",
        [string]$initialDirectory = "",
        [string]$fileTypeFilter = "All Files (*.*)|*.*"
    )

    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.title = $title
    $saveFileDialog.initialDirectory = $initialDirectory
    $saveFileDialog.Filter = $fileTypeFilter
    $result = $saveFileDialog.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $filePath = $saveFileDialog.FileName
        $fileExtension = [System.IO.Path]::GetExtension($filePath).ToLower()
        $contentType = $content.GetType().Name

        try {
            if ($exportMethods.ContainsKey($fileExtension)) {
                $method = $exportMethods[$fileExtension]
                if ($contentType -in $method.ValidTypes) {
                    & $method.ExportFunction $content $filePath # Call the export function with & to avoid security restrictions
                } else {
                    throw "content type $contentType is not suitable for $fileExtension export."
                }
            } else {
                # Default case for unknown file types
                $stringContent = $content | Out-String
                [System.IO.File]::WriteAllText($filePath, $stringContent)
            }

            return $filePath
        } catch {
            Write-Error "Failed to save file: $_"
            return $null
        }
    } else {
        Write-Host "Save operation cancelled."
        return $null
    }
}

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
        -prompt "Please enter the value you are searching for" `
        -title "Search Value" `
        -validationPattern '^\S+$' `
        -errorMessage "Invalid input. Please enter a non-empty search value without spaces."

    $columnName = Get-LargeTextInput `
        -prompt "Enter the column name that contains the value you are searching for" `
        -title "Column Name" `
        -validation '^[a-zA-Z0-9_]+$' `
        -errorMessage "Invalid input. Please enter a valid column name."

    $tolerance = Get-ToleranceInput

    $returnWholeRow = Get-YesNoInput-Bool -Prompt "Do you want to return the whole row of data when we find matches within the tolerance you set?"

    try {
        $matchingStringsResults = Find-ExcelContent `
            -SelectedFile $selectedFile `
            -SearchVal $searchVal `
            -ColumnName $columnName `
            -Tolerance $tolerance `
            -ReturnWholeRow $returnWholeRow

        $resultCount = $matchingStringsResults.Count
        if ($resultCount -gt 0) {
            $saveResults = Get-YesNoInput-Bool -Prompt "Do you want to save the results?"
            if ($saveResults) {
                Save-File -Content $matchingStringsResults -Title "Save the Results File" -InitialDirectory $initialDirectory -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" 
            }
        }
    }
    catch {
        Write-Error "An error occurred while searching the file: $_"#_catches the error message and displays it
    }

    [System.Windows.Forms.MessageBox]::Show("Search completed. Press OK to exit.", "Search Complete", [System.Windows.Forms.MessageBoxButtons]::OK)
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
    <#
        .SYNOPSIS
            Prompts the user for a tolerance level for string comparison.

        .DESCRIPTION
            Prompts the user with a message box to enter a tolerance level for string comparison.
            Returns the tolerance level as an integer.

        .EXAMPLE
            Get-ToleranceInput
            This example prompts the user for a tolerance level and returns the value as an integer.
    #>
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
    #>
    param (
        [string]$prompt
    )
    $result = [System.Windows.Forms.MessageBox]::Show($prompt, "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    return ($result -eq 'Yes')
}

Search-ExcelFileWithUI

