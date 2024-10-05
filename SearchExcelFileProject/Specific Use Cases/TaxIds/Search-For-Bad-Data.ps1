Import-Module ImportExcel
Add-Type -AssemblyName System.Windows.Forms

if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
    Write-Host "The ImportExcel module is not installed. Attempting to install..."
    try {
        Install-Module -Name ImportExcel -Force -Scope CurrentUser
        Write-Host "ImportExcel module installed successfully."
    }
    catch {
        Write-Error "Failed to install the ImportExcel module. Please install it manually by running 'Install-Module -Name ImportExcel' as an administrator. Run powershell as administrator"
        exit
    }
}

try {
    Import-Module ImportExcel
    Write-Host "ImportExcel module imported successfully."
}
catch {
    Write-Error "Failed to import the ImportExcel module. Please ensure it's installed correctly."
    exit
}

function Search-For-Bad-Data {
    [CmdletBinding()]
    Param()

    $VerbosePreference = "Continue"

    function Log-Step {
        param([string]$message)
        Write-Verbose "$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss') - $message"
    }

    function Update-ProgressBar {
        param (
            [int]$completed,
            [int]$total
        )
        $percentComplete = [math]::Min(100, [math]::Max(0, [math]::Round(($completed / $total) * 100)))
        $filledLength = [math]::Round($percentComplete / 2)
        $emptyLength = 50 - $filledLength
        $progressBar = "[" + "=" * $filledLength + " " * $emptyLength + "]"
        $progressText = "{0,3}% {1} {2}/{3}" -f $percentComplete, $progressBar, $completed, $total
        Write-Host "`r$progressText" -NoNewline
    }

    try {
        Log-Step "Starting Search for Bad Data in Excel File"

        $initialDirectory = Get-StartLocation
        $selectedFile = Open-File -Title "Select the Input Excel File" -InitialDirectory $initialDirectory -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" 
        Log-Step "File selected: $selectedFile"

        $excelData = Import-Excel -Path $selectedFile -ErrorAction Stop
        Log-Step "Excel file imported successfully. Row count: $($excelData.Count)"

        $columnName = "Tax_Id"
        Log-Step "Using column: $columnName"

        if (-not ($excelData[0].PSObject.Properties.Name -contains $columnName)) {
            Log-Step "Available columns: $($excelData[0].PSObject.Properties.Name -join ', ')"
            throw "The column '$columnName' does not exist in the Excel file."
        }

        $taxIds = $excelData.$columnName
        Log-Step "Extracted Tax IDs. Count: $($taxIds.Count)"

        $badTaxIds = [System.Collections.Generic.HashSet[string]]::new()
        $seenSTaxIds = [System.Collections.Generic.HashSet[string]]::new()
        $seenTTaxIds = [System.Collections.Generic.HashSet[string]]::new()

        Log-Step "Starting processing of Tax IDs"
        for ($i = 0; $i -lt $taxIds.Count; $i++) {
            $currentTaxId = $taxIds[$i]
            $prefix = $currentTaxId.Substring(0, 1)

            if ($prefix -eq 'S') {
                if ($seenSTaxIds.Contains($currentTaxId)) {
                    $badTaxIds.Add($currentTaxId) | Out-Null
                } else {
                    $seenSTaxIds.Add($currentTaxId) | Out-Null
                }
            } elseif ($prefix -eq 'T') {
                $seenTTaxIds.Add($currentTaxId) | Out-Null
            }

            for ($j = $i + 1; $j -lt $taxIds.Count; $j++) {
                $comparisonResult = Compare-Tax_Id_Values -Str1 $currentTaxId -Str2 $taxIds[$j] -Tolerance 1
                if ($comparisonResult -eq 1) {  # One digit off
                    $badTaxIds.Add($currentTaxId) | Out-Null
                    $badTaxIds.Add($taxIds[$j]) | Out-Null
                }
            }

            Update-ProgressBar -completed ($i + 1) -total $taxIds.Count
        }

        Write-Host "`nProcessing completed"
        Log-Step "Analysis completed"
        Log-Step "Found $($badTaxIds.Count) potentially bad Tax IDs"
        $fullRowData = $excelData | Where-Object { $_.$columnName -in $badTaxIds }
        if ($fullRowData.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No bad Tax Ids found.", "Search Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        } else {
            Write-Host "Found $($fullRowData.Count) rows with potentially bad Tax IDs."
            if (Get-YesNoInput-Bool "Would you like to save the results to a file?") {
                Save-File -Content $fullRowData -Title "Save the Results File" -InitialDirectory $initialDirectory
            }
        }
    }
    catch {
        Write-Error "An error occurred while searching the file: $_"
        Write-Verbose "Error details: $($_.Exception.Message)"
        Write-Verbose "Error occurred at: $($_.InvocationInfo.PositionMessage)"
    }

    Log-Step "Search completed"
    [System.Windows.Forms.MessageBox]::Show("Search completed. Press OK to exit.", "Search Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
}

function Compare-Tax_Id_Values {
    <#
        .SYNOPSIS
            Compare two strings with a given tolerance.
        .DESCRIPTION
            This function compares two strings with a given tolerance. If the strings have the same prefix and are
            within the tolerance, they are considered similar. The tolerance specifies the number of differences allowed.
        .PARAMETER Str1
            The first string to compare.
        .PARAMETER Str2
            The second string to compare.
        .PARAMETER Tolerance
            The number of differences allowed between the strings.
        .EXAMPLE
            Compare-Tax_Id_Values -Str1 "S12345" -Str2 "S12346" -Tolerance 1
            This example compares the strings "S12345" and "S12346" with a tolerance of 1.
            The function will return 1, indicating that the strings are similar (one digit off).

            Compare-Tax_Id_Values -Str1 "S12345" -Str2 "T12345" -Tolerance 1
            This example compares the strings "S12345" and "T12345" with a tolerance of 1.
            The function will return 0, indicating that the strings are not similar because they are trust/business vs ssn numbers.


    #>
    [CmdletBinding()]
    Param(
        [string]$str1,
        [string]$str2,
        [int]$tolerance
    )
    $parts1 = $str1 -split ' '
    $parts2 = $str2 -split ' '

    # If the prefixes are different, strings are not similar
    if ($parts1[0] -ne $parts2[0]) {
        return 0  # Not similar
    }

    if ($str1 -eq $str2) {
        return 2  # Exact match
    }
    $differences = 0
    for ($i = 0; $i -lt $parts1[1].Length -and $i -lt $parts2[1].Length; $i++) {
        if ($parts1[1][$i] -ne $parts2[1][$i]) {
            $differences++
            if ($differences -gt $tolerance) {
                return 0  # Not similar
            }
        }
    }
    return 1  # Similar (one digit off)
}

function Open-File {
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
        Write-Host "File selected: $selectedFile"
        return $selectedFile
    } else {
        Write-Host "No file was selected."
        exit
    }
}

function Get-StartLocation {
    $initialDirectory = $PWD.Path 
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = $env:USERPROFILE 
    }
    if (-not (Test-Path -Path $initialDirectory)) {
        $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    }
    return $initialDirectory
}

function Get-YesNoInput-Bool {
    param (
        [string]$prompt
    )
    $result = [System.Windows.Forms.MessageBox]::Show($prompt, "Confirmation", [System.Windows.Forms.MessageBoxButtons]::YesNo)
    return ($result -eq 'Yes')
}

function Save-File {
    [CmdletBinding()]
    Param(
        [Parameter(Mandatory=$true)]
        [object]$content,
        [string]$title = "Save Excel File",
        [string]$initialDirectory = ""
    )

    $saveFileDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveFileDialog.Title = $title
    $saveFileDialog.InitialDirectory = $initialDirectory
    $saveFileDialog.Filter = "Excel Files (*.xlsx)|*.xlsx"
    $saveFileDialog.DefaultExt = "xlsx"
    $saveFileDialog.AddExtension = $true
    $result = $saveFileDialog.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        $filePath = $saveFileDialog.FileName
        
        try {
            $content | Export-Excel -Path $filePath -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow

            Write-Host "Excel file saved successfully to: $filePath"
            return $filePath
        } catch {
            Write-Error "Failed to save Excel file: $_"
            return $null
        }
    } else {
        Write-Host "Save operation cancelled."
        return $null
    }
}

if (Get-Module -Name ImportExcel) {
    Search-For-Bad-Data
} else {
    Write-Error "The ImportExcel module is not available. Please ensure it's installed and try again."
}