BeforeAll {
    . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
}

Describe "Compare-ObjectsExt" {
    It "Returns expected output" {
        Compare-ObjectsExt | Should -Be "YOUR_EXPECTED_VALUE"
    }
}
