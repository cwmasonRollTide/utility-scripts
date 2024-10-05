# Quick Guide

- Copy contents of Search-For-Bad-Data.ps1 file into a file on your computer

- Wherever you save the file is fine. for simplicity, let's say,
    * C:\Users\<username>\Desktop\Search.ps1 is fine.

- Open "Powershell", Run as Administrator

- type in the command line
    ```powershell
    > cd " C:\Users\<username>\Desktop"
    ```

- When you're in the same directory as the Search.ps1 file, 
    type
    ```powershell
    > .\Search.ps1
    ```

- Should prompt you for your file! This script currently assumes the Tax_Id column is spelled and cased that way. 
- If that needs to change, change line 58 in the script. 
    * $columnName = "Tax_Id"
- This is a result of me being lazy after ripping out the logic from the generalized tool to prompt for a column for fuzzy matching lol