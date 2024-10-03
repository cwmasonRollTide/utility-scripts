Add-Type -AssemblyName System.Windows.Forms
Import-Module ImportExcel

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

            Write-Host "File saved successfully to: $filePath"
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