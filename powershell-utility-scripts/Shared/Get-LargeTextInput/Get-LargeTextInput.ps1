Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.Windows.Forms

function New-CustomForm {
    param (
        [string]$title,
        [int]$width = 500,
        [int]$height = 250
    )
    $form = New-Object System.Windows.Forms.Form
    $form.Text = $title
    $form.Size = New-Object System.Drawing.Size($width, $height)
    $form.StartPosition = "CenterScreen"
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $form.BackColor = [System.Drawing.Color]::FromArgb(240,240,240)
    return $form
}

function New-CustomPanel {
    param (
        [System.Windows.Forms.Form]$form,
        [int]$x = 10,
        [int]$y = 10,
        [int]$width = 465,
        [int]$height = 190
    )
    $panel = New-Object System.Windows.Forms.Panel
    $panel.Location = New-Object System.Drawing.Point($x, $y)
    $panel.Size = New-Object System.Drawing.Size($width, $height)
    $panel.BorderStyle = [System.Windows.Forms.BorderStyle]::None
    $panel.BackColor = [System.Drawing.Color]::White
    $form.Controls.Add($panel)
    return $panel
}

function New-CustomLabel {
    param (
        [System.Windows.Forms.Control]$parent,
        [string]$text,
        [int]$x,
        [int]$y,
        [int]$width,
        [int]$height,
        [string]$fontFamily = "Inter, Segoe UI, Arial, Sans-Serif",
        [int]$fontSize = 12,
        [System.Drawing.Color]$foreColor = [System.Drawing.Color]::Black
    )
    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point($x, $y)
    $label.Size = New-Object System.Drawing.Size($width, $height)
    $label.Text = $text
    $label.Font = New-Object System.Drawing.Font($fontFamily, $fontSize, [System.Drawing.FontStyle]::Regular)
    $label.TextAlign = [System.Drawing.ContentAlignment]::MiddleLeft
    $label.ForeColor = $foreColor
    $parent.Controls.Add($label)
    return $label
}

function New-CustomTextBox {
    param (
        [System.Windows.Forms.Control]$parent,
        [string]$defaultValue,
        [int]$x,
        [int]$y,
        [int]$width,
        [int]$height,
        [string]$fontFamily = "Inter, Segoe UI, Arial, Sans-Serif",
        [int]$fontSize = 12
    )
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point($x, $y)
    $textBox.Size = New-Object System.Drawing.Size($width, $height)
    $textBox.Font = New-Object System.Drawing.Font($fontFamily, $fontSize, [System.Drawing.FontStyle]::Regular)
    $textBox.Text = $defaultValue
    $parent.Controls.Add($textBox)
    return $textBox
}

function New-CustomButton {
    param (
        [System.Windows.Forms.Control]$parent,
        [string]$text,
        [int]$x,
        [int]$y,
        [int]$width = 75,
        [int]$height = 30,
        [string]$fontFamily = "Inter, Segoe UI, Arial, Sans-Serif",
        [int]$fontSize = 10,
        [System.Windows.Forms.DialogResult]$dialogResult,
        [System.Drawing.Color]$backColor,
        [System.Drawing.Color]$foreColor
    )

    $button = New-Object System.Windows.Forms.Button
    $button.Location = New-Object System.Drawing.Point($x, $y)
    $button.Size = New-Object System.Drawing.Size($width, $height)
    $button.Text = $text
    $button.Font = New-Object System.Drawing.Font($fontFamily, $fontSize, [System.Drawing.FontStyle]::Regular)
    $button.DialogResult = $dialogResult
    $button.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $button.BackColor = $backColor
    $button.ForeColor = $foreColor
    $parent.Controls.Add($button)

    return $button
}

function Get-LargeTextInput {
    param (
        [string]$prompt,
        [string]$title,
        [string]$defaultValue = "",
        [string]$validationPattern = '^\S+$',
        [string]$errorMessage = "Invalid input. Please enter a non-empty value without whitespace."
    )
    $form = New-CustomForm -title $title
    $panel = New-CustomPanel -form $form
    $form.Label = New-CustomLabel -parent $panel -text $prompt -x 20 -y 20 -width 425 -height 40
    $textBox = New-CustomTextBox -parent $panel -defaultValue $defaultValue -x 20 -y 70 -width 425 -height 30
    $errorLabel = New-CustomLabel -parent $panel -text "" -x 20 -y 110 -width 425 -height 30 -fontSize 10 -foreColor [System.Drawing.Color]::Red
    $okButton = New-CustomButton -parent $panel -text "OK" -x 295 -y 150 -dialogResult ([System.Windows.Forms.DialogResult]::OK) -backColor ([System.Drawing.Color]::FromArgb(0,120,215)) -foreColor ([System.Drawing.Color]::White)
    $cancelButton = New-CustomButton -parent $panel -text "Cancel" -x 380 -y 150 -dialogResult ([System.Windows.Forms.DialogResult]::Cancel) -backColor ([System.Drawing.Color]::White) -foreColor ([System.Drawing.Color]::Black)
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton
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
