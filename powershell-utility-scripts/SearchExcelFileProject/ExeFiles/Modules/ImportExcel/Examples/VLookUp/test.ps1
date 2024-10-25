$data = ConvertFrom-Csv @"
Products,YEAR2020,YEAR2021,YEAR2022,YEAR2023
Apple,4.971,2.579,2.841,4.771
Banana,2.971,1.579,1.841,2.771
Picasso,1.971,0.579,0.841,1.771
Flower,0.971,0.579,0.841,0.771
Pizza,5.971,3.579,3.841,6.771
"@

$xlfile = "$PSScriptRoot\test.xlsx"
Remove-Item $xlfile -ErrorAction SilentlyContinue

$excel = $data | Export-Excel $xlfile -AutoSize -AutoNameRange -PassThru

$null = $excel.Sheet1.Names.Add("Apple", (($excel.Sheet1.Cells[2, 2, 2, 5])))
$null = $excel.Sheet1.Names.Add("Banana", (($excel.Sheet1.Cells[3, 2, 3, 5])))
$null = $excel.Sheet1.Names.Add("Picasso", (($excel.Sheet1.Cells[4, 2, 4, 5])))
$null = $excel.Sheet1.Names.Add("Flower", (($excel.Sheet1.Cells[5, 2, 5, 5])))
$null = $excel.Sheet1.Names.Add("Pizza", (($excel.Sheet1.Cells[6, 2, 6, 5])))

Set-ExcelRange -Worksheet $excel.Sheet1 -Range C9 -Formula "=Apple Year2023"
Set-ExcelRange -Worksheet $excel.Sheet1 -Range C10 -Formula "=Banana Year2023"
Set-ExcelRange -Worksheet $excel.Sheet1 -Range C11 -Formula "=Picasso Year2023"
Set-ExcelRange -Worksheet $excel.Sheet1 -Range C12 -Formula "=Flower Year2023"
Set-ExcelRange -Worksheet $excel.Sheet1 -Range C13 -Formula "=Pizza Year2023"

Close-ExcelPackage $excel -Show