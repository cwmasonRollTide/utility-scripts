# SPECIFIC TO TAX ID ONE CHARACTER OFF ISSUE: Quick Guide

## Download/Save File

- Copy contents of Search-For-Bad-Data.ps1 file into a file on your computer

OR

   ```powershell
   git clone https://github.com/cwmasonRollTide/utility-scripts.git
   ```

   OR

- Go to https://github.com/cwmasonRollTide/utility-scripts
- Click the green "Code" button, then "Download ZIP"
- Extract the ZIP file to a location you can easily find (e.g., Desktop)

- Wherever you save the file is fine
  - C:\Users\<username>\Desktop\Search-For-Bad-Data.ps1

- Open "Powershell", Run as Administrator

- type in the command line

    ```powershell
    > cd  C:\Users\<username>\Desktop
    ```

------------------------------------------------------

## Once you Have a Saved .PS1 File

- When you're in the same directory as the Search.ps1 file,
    type

    ```powershell
    > .\Search-For-Bad-Data.ps1
    ```

  - NOTE: You may need to run:
  
      ```powershell
      Set-ExecutionPolicy RemoteSigned
      ```

   if you get an error about permissions or it doesn't run

- Should prompt you for your file! This script currently assumes the Tax_Id column is spelled and cased that way
- If that needs to change, change line 58 in the script
  - $columnName = "Tax_Id"
- This is a result of me being lazy after ripping out the logic from the generalized tool to prompt for a column for fuzzy matching lol
