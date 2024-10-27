. "$PSScriptRoot/Compare-Strings.ps1"
Import-Module Pester

Describe 'Compare-Strings' {
    Context 'Comparing two identical strings' {
        It 'Should return true' {
            $result = Compare-Strings 'Hello' 'Hello'
            $result | Should -Be $true 
        }
    }

    Context 'Comparing two different strings' {
        It 'Should return false' {
            $result = Compare-Strings 'Hello' 'World'
            $result | Should -Be $false
        }
    }

    Context 'Comparing case-sensitive strings' {
        It 'Should return false for different cases' {
            $result = Compare-Strings 'hello' 'Hello'
            $result | Should -Be $false  # Case-sensitive, so false
        }
    }

    Context 'Comparing empty strings' {
        It 'Should return true' {
            $result = Compare-Strings '' ''
            $result | Should -Be $true
        }
    }
}
