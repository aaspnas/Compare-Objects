BeforeAll {
  #  . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  . .\Compare-ObjectsExt.ps1
}

Describe "Compare-ObjectsExt" {
    It "Returns expected output for null values" {
        Compare-ObjectsExt $null $null | Should -BeNullOrEmpty
        Compare-ObjectsExt "" "" | Should -BeNullOrEmpty
        Compare-ObjectsExt $null "foo" | Should -Match '/ - Ref is null, but Diff has a value not null'
        Compare-ObjectsExt "foo" $null | Should -Match '/ - Ref is not null, but Diff has a null value'

    }
    It "Returns expected output for integer values" {
        Compare-ObjectsExt 1 1 | Should -BeNullOrEmpty

    }
    It "Notices difference between different data types" {
        Compare-ObjectsExt "foo" 1 | Should -Match '/ - Ref and Diff datatype names differ'

    }
    
}
