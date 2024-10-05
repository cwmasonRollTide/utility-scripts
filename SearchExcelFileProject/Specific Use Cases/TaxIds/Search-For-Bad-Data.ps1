Import-Module ImportExcel
Add-Type -AssemblyName System.Windows.Forms

function Search-For-Bad-Data {
    [CmdletBinding()]
    Param()

    $initialDirectory = Get-StartLocation
    $selectedFile = Open-File -Title "Select the Input Excel File" -InitialDirectory $initialDirectory -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx" 
    $columnName = "Tax_Id"
    $toleranceZero = 0
    $toleranceOne = 1
    try {
        $excelData = Import-Excel -Path $selectedFile
        $listWithToleranceOne = [System.Collections.Concurrent.ConcurrentBag[object]]::new()
        $listWithToleranceZero = [System.Collections.Concurrent.ConcurrentBag[object]]::new()

        $excelData | ForEach-Object -Parallel {
            $row = $_
            $columnName = $using:columnName
            $excelData = $using:excelData
            $toleranceOne = $using:toleranceOne
            $toleranceZero = $using:toleranceZero
            $listWithToleranceOne = $using:listWithToleranceOne
            $listWithToleranceZero = $using:listWithToleranceZero

            $tempListOne = Find-ExcelContent -ExcelData $excelData -SearchVal $row.$columnName -ColumnName $columnName -Tolerance $toleranceOne -ReturnWholeRow $false
            foreach ($item in $tempListOne) {
                $listWithToleranceOne.Add($item)
            }

            $tempListZero = Find-ExcelContent -ExcelData $excelData -SearchVal $row.$columnName -ColumnName $columnName -Tolerance $toleranceZero -ReturnWholeRow $false
            foreach ($item in $tempListZero) {
                $listWithToleranceZero.Add($item)
            }
        } -ThrottleLimit 16

        # Find the tax ids that are in the list with tolerance one but not in the list with tolerance zero
        $listDifference = $listWithToleranceOne | Where-Object {$_ -notin $listWithToleranceZero}
        # Find the rows from the original full data that have the possibly bad tax ids
        $fullRowData = $excelData | Where-Object { $listDifference.$columnName -contains $_.$columnName }
        if ($fullRowData.Count -eq 0) {
            [System.Windows.Forms.MessageBox]::Show("No bad Tax Ids found.", "Search Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            return
        } else {
            if (Get-YesNoInput-Bool "Would you like to save the results to a file?") {
                Save-File -Content $fullRowData -Title "Save the Results File" -InitialDirectory $initialDirectory -FileTypeFilter "Excel Files (*.xlsx)|*.xlsx"
            }
        }
    }
    catch {
        Write-Error "An error occurred while searching the file: $_"
    }

    [System.Windows.Forms.MessageBox]::Show("Search completed. Press OK to exit.", "Search Complete", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
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

function Compare-Strings {
    [CmdletBinding()]
    Param(
        [string]$str1,
        [string]$str2,
        [int]$tolerance
    )
    $str1 = $str1.ToLower()
    $str2 = $str2.ToLower()
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

function Find-ExcelContent {
    [CmdletBinding()]
    param (
        [System.Object[]]$excelData,
        [string]$searchVal,
        [string]$columnName,
        [int]$tolerance,
        [boolean]$returnWholeRow
    )
    $matchingStringsResults = @()
    foreach ($row in $excelData) {
        $currentVal = $row.$columnName
        if (Compare-Strings -Str1 $searchVal -Str2 $currentVal -Tolerance $tolerance) {
            if ($returnWholeRow) {
                $matchingStringsResults += $row
            } else {
                $matchingStringsResults += [PSCustomObject]@{$columnName = $currentVal}
            }
        }
    }

    return $matchingStringsResults
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

Search-For-Bad-Data