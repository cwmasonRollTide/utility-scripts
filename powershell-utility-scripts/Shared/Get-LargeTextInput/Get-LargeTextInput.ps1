Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

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





