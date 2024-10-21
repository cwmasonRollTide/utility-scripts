# Excel Search Tool

## Table of Contents

- [Excel Search Tool](#excel-search-tool)
  - [Table of Contents](#table-of-contents)
  - [Introduction](#introduction)
  - [Features](#features)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Using PowerShell Script](#using-powershell-script)
    - [Using Executable](#using-executable)
  - [Building Executable](#building-executable)
  - [How It Works](#how-it-works)
  - [Troubleshooting](#troubleshooting)
  - [Dependencies](#dependencies)
  - [Contributing](#contributing)
  - [License](#license)

## Introduction

The Excel Search Tool is a utility to search for similar strings/values within Excel files. It allows users to specify a search value, column name, and tolerance level to find matching or near-matching entries in Excel spreadsheets. This tool is particularly useful for data cleaning, duplicate detection, and fuzzy matching tasks.

## Features

- Search for exact or similar strings in Excel files
- Adjustable tolerance level for fuzzy matching
- Option to return entire rows or just matching values
- User-friendly interface for input and file selection
- Exportable results

## Installation

1. Download the project:
   - Go to https://github.com/cwmasonRollTide/utility-scripts
   - Click the green "Code" button, then "Download ZIP"
   - Extract the ZIP file to a location you can easily find (e.g., Desktop)

2. Ensure you have PowerShell 5.1 or later:
   - Press Win + X, select "Windows PowerShell" or "PowerShell"
   - Run this command to check your version:

     ```powershell
     $PSVersionTable.PSVersion
     ```

   - If lower than 5.1, update PowerShell from Microsoft's website

3. Install required module:
   - Open PowerShell as administrator
   - Run this command:

     ```powershell
     Install-Module -Name ImportExcel -Scope CurrentUser -Force
     ```

## Usage

### Using PowerShell Script

1. Clone or download the project directory

   ```powershell
   git clone https://github.com/cwmasonRollTide/utility-scripts.git
   ```

   OR

   Download the project:
   - Go to https://github.com/cwmasonRollTide/utility-scripts
   - Click the green "Code" button, then "Download ZIP"
   - Extract the ZIP file to a location you can easily find (e.g., Desktop)

2. Open PowerShell:
   - Press `Win + X` and select "Windows PowerShell" or "PowerShell" from the menu.
   - Alternatively, search for "PowerShell" in the Start menu and open it.

3. Navigate to the project directory:

   ```powershell
   cd ~\utility-scripts\SearchExcelFileProject
   ```

   - example: if you downloaded to your desktop,

   ```powershell
    cd C:\Users\<Your Username>\Desktop\utility-scripts\SearchExcelFileProject
   ```

4. Run the script:

   ```powershell
   .\Search-ExcelFileWithUI.ps1
   ```

   - NOTE: You may need to run:
  
      ```powershell
      Set-ExecutionPolicy RemoteSigned
      ```

   if you get an error about permissions or it doesn't run

5. Follow the on-screen prompts to select your Excel file, enter search parameters, and view results.

### Using Executable

1. Locate the `Search-ExcelFile.exe` in the project directory. It is in ~\utility-scripts\SearchExcelFileProject\Search-ExcelFile.exe

2. Download File

3. Double-click the executable to run it.

4. Follow the on-screen prompts to select your Excel file, enter search parameters, and view results.

## Building Executable

Due to difficulties (*cough* *cough* skill issues) there is a different version of the script with all the functions in one file
in the SearchExcelFileProject/ExeFiles directory. This makes it simpler to use the ps2exe utility to convert the powershell scripts into an .exe

1. Navigate to the project directory:

   ```powershell
   cd ~\utility-scripts\SearchExcelFileProject
   ```

2. Install the necessary modules

   ```powershell
   Install-Module -Name ps2exe -Scope CurrentUser -Force
   Install-Module -Name ImportExcel -Scope CurrentUser -Force
   ```

3. Define your variables and run the command to make your desired .exe file!

```powershell
      ps2exe `
         -InputFile "~\utility-scripts\SearchExcelFileProject\ExeFiles\Search-ExcelFileWithUI.ps1" `
         -OutputFile $outputPath `
         -Verbose `
         -Title $title `
         -Version $version `
         -Description $description `
         -Company $company `
         -Product $product `
         -Copyright $copyright `
         -RequireAdmin `
         -NoConsole `
         -ErrorAction Stop `
         -IconFile $iconPath
```

## How It Works

1. The tool prompts you to select an Excel file.

2. You enter a search value, specify the column to search in, and set a tolerance level for fuzzy matching.

3. The script searches the specified column for entries that match or are similar to your search value, within the given tolerance.

4. Results are displayed in the console and can be optionally saved to a file.

## Troubleshooting

- If you encounter permission issues, try running PowerShell as an administrator.

- Ensure that your Excel file is not open in another program when running the search.

- Check if your data is "clean" or if it has a bunch of funny characters in there.

- Have you tried unplugging it and plugging it back in

## Dependencies

- [Import Excel](https://www.powershellgallery.com/packages/ImportExcel/7.8.6)
  - This tool makes it incredibly simple to import excel files and process them quickly
   and it wasn't built into powershell initially

- [Ps2 Exe](https://www.powershellgallery.com/packages/ps2exe/1.0.13)
  - This tool makes it incredibly simple to convert a powershell script into an executable

## Contributing

I am not really interested in contributions to this repo at this time. I have another repo for unfinished scripts where I just mess around, I want this one to be for "complete" projects I can share

## License

This project is licensed under the MIT License - see the LICENSE file for details.
