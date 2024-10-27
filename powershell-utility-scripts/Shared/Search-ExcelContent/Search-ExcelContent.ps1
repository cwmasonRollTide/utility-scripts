. "$PSScriptRoot\..\Shared\Compare-Strings\Compare-Strings.ps1"

function Search-ExcelContent {
<#
    .SYNOPSIS
        Finds matching strings within a specified tolerance in an excel file. Either returns the entire rows or just the matching values.

    .DESCRIPTION
        The Search-ExcelContent function searches for matching strings within a specified tolerance in an excel file. 
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
        Search-ExcelContent -selectedFile "C:\path\to\file.excel" -searchVal "apple" -columnName "Fruit" -tolerance 2 -returnWholeRow "y"
        This example searches for the value "apple" within the "Fruit" column of the excel file located at "C:\path\to\file.excel". It allows a tolerance of 2 characters for string comparison and returns the entire row for each matching string.

    .EXAMPLE
        Search-ExcelContent -selectedFile "C:\path\to\file.excel" -searchVal "banana" -columnName "Fruit" -tolerance 1 -returnWholeRow "n"
        This example searches for the value "banana" within the "Fruit" column of the excel file located at "C:\path\to\file.excel". It allows a tolerance of 1 character for string comparison and returns only the matching value for each match.

    .OUTPUTS
        System.Object[] | string[] 
        An array of matching strings or rows from the excel file, depending on the returnWholeRow parameter.

#>
    [CmdletBinding()]
    param (
        [string]$selectedFile,
        [string]$searchVal,
        [string]$columnName,
        [int]$tolerance,
        [boolean]$returnWholeRow
    )
    $matchCount = 0
    $excelData = Import-Excel -Path $selectedFile
    $matchingStringsResults = @()

    Write-Host "Searching for matches... This may take a while for large datasets."
    Write-Host "Search value: '$searchVal', Column: '$columnName', Tolerance: $tolerance"
    Write-Host "-------------------------------------------"
    foreach ($row in $excelData) {
        $currentVal = $row.$columnName
        if (Compare-Strings -Str1 $searchVal -Str2 $currentVal -Tolerance $tolerance) {
            $matchCount++
            if ($returnWholeRow) {
                $matchingStringsResults += $row
                $output = "Match #$matchCount :`n"
                $properties = $row.PSObject.Properties
                $maxKeyLength = ($properties | ForEach-Object { $_.Name.Length } | Measure-Object -Maximum).Maximum
                foreach ($prop in $properties) {
                    $paddedKey = $prop.Name.PadRight($maxKeyLength)
                    $output += "  $paddedKey : $($prop.Value)`n"
                }
            } else {
                $matchingStringsResults += [PSCustomObject]@{$columnName = $currentVal}
                $output = "Match #$matchCount : $currentVal"
            }
            Write-Host $output
            Write-Host "-------------------------------------------`n"
        }
    }
    Write-Host "Search complete. Total matches found: $matchCount"
    return $matchingStringsResults
}
