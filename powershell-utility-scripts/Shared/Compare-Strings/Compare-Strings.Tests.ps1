Describe "Compare-Strings" {
    Context "Comparing two identical strings" {
        It "Should return true" {
            Compare-Strings "hello" "hello" | Should -Be $true
        }
    }

    Context "Comparing two different strings" {
        It "Should return false" {
            Compare-Strings "hello" "world" | Should -Be $false
        }
    }

    Context "Comparing case-sensitive strings" {
        It "Should return false for different cases" {
            Compare-Strings "hello" "HELLO" | Should -Be $false
        }
    }

    Context "Comparing empty strings" {
        It "Should return true" {
            Compare-Strings "" "" | Should -Be $true 
        }
    }
}


