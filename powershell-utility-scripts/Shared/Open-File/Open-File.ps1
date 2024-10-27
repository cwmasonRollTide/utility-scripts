Add-Type -AssemblyName System.Windows.Forms

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
        Write-Host "File selected: $selectedFile"
        return $selectedFile
    } else {
        Write-Host "No file was selected."
        exit
    }
}






