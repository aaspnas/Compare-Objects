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
    It "Returns expected output for strings" {
        Compare-ObjectsExt "foo" "foo" | Should -BeNullOrEmpty

    }
    It "Notices difference between different data types" {
        Compare-ObjectsExt "foo" 1 | Should -Match '/ - Ref and Diff datatype names differ'

    }
    
} 
Describe "isSimpleType" {
    It "returns true for simple types" {
        isSimpleType ("foo").GetType().Name | Should -BeTrue
        isSimpleType (1).GetType().Name | Should -BeTrue
        isSimpleType (1.2).GetType().Name | Should -BeTrue
        isSimpleType ("a",'b',"c").GetType().Name | Should -BeFalse
    }
}

Describe "Write-Diff" {
    It "returns text" {
        Write-Diff '/' "is ok" | Should -Match '/ - is ok'

    }
}

