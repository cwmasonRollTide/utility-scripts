Import-Module ImportExcel

# Define the number of employees
$numberOfEmployees = 10000

# Create an array to hold our employee data
$employees = @()

# Lists for random data generation
$firstNames = @("James", "John", "Robert", "Michael", "William", "David", "Richard", "Joseph", "Thomas", "Charles", "Mary", "Patricia", "Jennifer", "Linda", "Elizabeth", "Barbara", "Margaret", "Susan", "Dorothy", "Lisa")
$lastNames = @("Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller", "Davis", "Rodriguez", "Martinez", "Anderson", "Taylor", "Thomas", "Moore", "Jackson", "Martin", "Lee", "Perez", "Thompson", "White")
$streetNames = @("Main", "Oak", "Pine", "Maple", "Cedar", "Elm", "Washington", "Park", "Lake", "Hill")
$cities = @("New York", "Los Angeles", "Chicago", "Houston", "Phoenix", "Philadelphia", "San Antonio", "San Diego", "Dallas", "San Jose")
$states = @("NY", "CA", "IL", "TX", "AZ", "PA", "FL", "OH", "MI", "GA")
$companies = @("TechCorp", "GlobalFinance", "MegaRetail", "EcoSolutions", "HealthInnovations")

# Function to generate a random SSN-like Tax ID with a trust indicator
function Get-RandomTaxId {
    param(
        [bool]$isTrust
    )
    $prefix = if ($isTrust) { "T" } else { "S" }
    $number = Get-Random -Minimum 100000000 -Maximum 999999999
    return "$prefix $number"
}

# Function to increment a Tax ID by one (simulating Excel auto-increment)
function Increment-TaxId {
    param($taxId)
    $parts = $taxId -split ' '
    $prefix = $parts[0]
    $number = [int]$parts[1]
    $incrementedNumber = $number + 1
    return "$prefix {0:D9}" -f $incrementedNumber
}

# Function to generate a random account number
function Get-RandomAccountNumber {
    return "ACC" + (Get-Random -Minimum 100000000 -Maximum 999999999)
}

# Function to generate a random trust ID
function Get-RandomTrustId {
    return "TRUST" + (Get-Random -Minimum 10000 -Maximum 99999)
}

# Generate employee data
for ($i = 1; $i -le $numberOfEmployees; $i++) {
    $isTrust = (Get-Random -Minimum 0 -Maximum 100) -lt 10  # 10% chance of being a trust
    $employee = [PSCustomObject]@{
        EmployeeId = $i
        FirstName = $firstNames | Get-Random
        LastName = $lastNames | Get-Random
        Tax_Id = Get-RandomTaxId -isTrust $isTrust
        Address = "$((Get-Random -Minimum 100 -Maximum 9999)) $($streetNames | Get-Random) St"
        City = $cities | Get-Random
        State = $states | Get-Random
        ZipCode = "$(Get-Random -Minimum 10000 -Maximum 99999)"
        AccountNumber = Get-RandomAccountNumber
        Company = $companies | Get-Random
        IsTrust = $isTrust
        TrustId = if ($isTrust) { Get-RandomTrustId } else { $null }
    }
    $employees += $employee
}

# Introduce Tax ID errors (about 5% of employees)
$errorCount = [math]::Floor($numberOfEmployees * 0.05)
$errorGroups = [math]::Floor($errorCount / 3)  # We'll create groups of 3 related errors

for ($i = 0; $i -lt $errorGroups; $i++) {
    $startIndex = Get-Random -Minimum 0 -Maximum ($numberOfEmployees - 3)
    $company = $companies | Get-Random
    $lastName = $lastNames | Get-Random
    $isTrust = (Get-Random -Minimum 0 -Maximum 100) -lt 30  # 30% chance for the group to be a trust
    $trustId = if ($isTrust) { Get-RandomTrustId } else { $null }

    $baseTaxId = Get-RandomTaxId -isTrust $isTrust

    for ($j = 0; $j -lt 3; $j++) {
        $index = $startIndex + $j
        if ($j -eq 0) {
            $currentTaxId = $baseTaxId
        } else {
            $currentTaxId = Increment-TaxId -taxId $baseTaxId
        }

        $employees[$index].Tax_Id = $currentTaxId
        $employees[$index].Company = $company
        $employees[$index].LastName = $lastName
        $employees[$index].IsTrust = $isTrust
        $employees[$index].TrustId = $trustId
    }
}

# Export to Excel
$filePath = "../data/GeneratedTestData_10000.xlsx"
$employees | Export-Excel -Path $filePath -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow

# Debug: Check if file was created
if (Test-Path $filePath) {
    Write-Host "Excel file created successfully at $filePath"
} else {
    Write-Host "Error: Excel file was not created"
}

Write-Host "Total number of employees generated: $($employees.Count)"
Write-Host "Number of introduced Tax ID error groups: $errorGroups"