function Compare-Strings {
   <#
      .SYNOPSIS
         Compares two strings character by character and checks if the number of differences is less than or equal to a given tolerance.

      .DESCRIPTION
         The Compare-Strings function takes in two strings and a tolerance value. It iterates over each character in the first string and compares it with the corresponding character in the second string. If the characters are not equal, it increments a differences counter. Finally, it checks if the total number of differences is less than or equal to the tolerance value.

      .PARAMETER str1
         The first string to compare.

      .PARAMETER str2
         The second string to compare.

      .PARAMETER tolerance
         The maximum number of character differences allowed between the two strings.

      .EXAMPLE
         Compare-Strings -str1 "hello" -str2 "helli" -tolerance 1
         Returns True because there is only one character difference between the two strings, which is less than or equal to the tolerance.

      .OUTPUTS
         Boolean. Returns True if the number of character differences between the two strings is less than or equal to the tolerance, otherwise False.

      .NOTES
         Author: Connor Mason
         Date: 10/2/2024
   #>
   [CmdletBinding()]
   Param(
      [string]$str1,
      [string]$str2,
      [int]$tolerance
   )
   $differences = 0
   $maxLength = [Math]::Max($str1.Length, $str2.Length)
   $minLength = [Math]::Min($str1.Length, $str2.Length)

   for ($i = 0; $i -lt $maxLength; $i++) {
      if ($i -lt $minLength) {
         if ($str1[$i] -ne $str2[$i]) {
            $differences++
         }
      } else {
         $differences++
      }

      if ($differences -gt $tolerance) {
         return $false
      }
   }

   return $differences -le $tolerance
}

function Compare-StringsRegex {
   <#
      .SYNOPSIS
         Compares two strings using regex pattern matching within a given tolerance.

      .DESCRIPTION
         Uses regex to compare strings, allowing for a specified number of differences.

      .PARAMETER str1
         The first string to compare.

      .PARAMETER str2
         The second string to compare.

      .PARAMETER tolerance
         The maximum number of character differences allowed.

      .EXAMPLE
         Compare-StringsRegex -str1 "hello" -str2 "helli" -tolerance 1
         Returns True (one character difference, within tolerance).

      .OUTPUTS
         Boolean. True if differences <= tolerance, otherwise False.

      .NOTES
         Author: Connor Mason
         Date: 10/2/2024
   #>
   [CmdletBinding()]
   Param(
      [string]$str1,
      [string]$str2,
      [int]$tolerance
   )

   function New-tolerancePattern([string]$str) {
      $pattern = "^" + ($str.ToCharArray() | ForEach-Object { "($([regex]::Escape($_))|.){1}" }) -join ""# Create a regex pattern that allows for a certain number of differences
      return $pattern + "{0,$tolerance}$"
   }

   $pattern1 = New-tolerancePattern $str1
   $pattern2 = New-tolerancePattern $str2
   # Check if either string matches the pattern of the other within the tolerance. Criss Cross, Everybody clap your hands
   return ($str2 -match $pattern1) -or ($str1 -match $pattern2)
}