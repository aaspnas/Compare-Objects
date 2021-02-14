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
        Compare-ObjectsExt 1 2 | Should -Match '>> 1'
        Compare-ObjectsExt 1 2 | Should -Match '<< 2'

    }
    It "Returns expected output for strings" {
        Compare-ObjectsExt "foo" "foo" | Should -BeNullOrEmpty
        Compare-ObjectsExt "foo" "fo1o" | Should -Match ">> foo"
        Compare-ObjectsExt "foo" "fo1o" | Should -Match "<< fo1o"
    }
    It "Returns expected output for lists" {
        Compare-ObjectsExt ("foo", "bar", "baz") ("foo", "bar", "baz") | Should -BeNullOrEmpty
        Compare-ObjectsExt ("foo", "bar", "baz") ("foo", "bar") | Should -Match "Ref and Diff list lenght differ|Ref is not null, but Diff has a null value"
    } 
    It "Returns expected output for hashes" {
        Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "bar"}) (@{ ID = 1; Name = "foo"; Description = "bar"})  | Should -BeNullOrEmpty 
        Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "baz"}) (@{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match ">> baz" 
        Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "baz"}) (@{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match "<< bar" 

    }
    It "Returns expected output for composite objects" {
        Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  | Should -BeNullOrEmpty 
        Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "baz"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match ">> baz" 
        Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "baz"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match "<< bar" 
        Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "baz"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = ("foo","bar")})   | Should -match "Ref and Diff datatype names differ"
    }


    It "Notices difference between different data types" {
        Compare-ObjectsExt "foo" 1 | Should -Match '/ - Ref and Diff datatype names differ'

    }


    It "Has help content" {
        Get-Help Compare-ObjectsExt -Full | Should -Match "DESCRIPTION"
        Get-Help Compare-ObjectsExt -Full | Should -Match "https://github.com"


    }

} 
Describe "isSimpleType" {
    It "returns true for simple types" {
        isSimpleType ("foo") | Should -BeTrue
        isSimpleType (1) | Should -BeTrue
        isSimpleType (1.2) | Should -BeTrue
        isSimpleType ("a",'b',"c") | Should -BeFalse
    }
}

Describe "isList" {
    It "returns true for list objects" {
        isList ("foo") | Should -BeFalse
        islist ("a",'b',"c") | Should -BeTrue
    }
}

Describe "isHash" {
    It "returns true for list objects" {
        isHash ("foo") | Should -BeFalse
        isHash ("a",'b',"c") | Should -BeFalse
        isHash ([ordered] @{foo = 1; bar = 2}) | Should -BeTrue
        isHash (@{foo = 1; bar = 2}) | Should -BeTrue
    }
}
Describe "Write-Diff" {
    It "returns text" {
        Write-Diff '/' "is ok" | Should -Match '/ - is ok'

    }
}

