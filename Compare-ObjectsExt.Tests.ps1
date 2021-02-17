BeforeAll {
  #  . $PSCommandPath.Replace('.Tests.ps1', '.ps1')
  . .\Compare-ObjectsExt.ps1
}

Describe "Compare-ObjectsExt" {
    Context "Comparision of simples values and null values" {
        It "Returns expected output for null values" {
            Compare-ObjectsExt $null $null | Should -BeNullOrEmpty
            Compare-ObjectsExt "" "" | Should -BeNullOrEmpty
            Compare-ObjectsExt $null "foo" | Should -Match '/ - Ref is null, but Diff has a value'
            Compare-ObjectsExt "foo" $null | Should -Match '/ - Ref has a value, but Diff is null'

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
    }
    Context "Comparision of lists and hashes" {
        It "Returns expected output for lists" {
            Compare-ObjectsExt ("foo", "bar", "baz") ("foo", "bar", "baz") | Should -BeNullOrEmpty
            Compare-ObjectsExt ("foo", "bar", "baz") ("foo", "bar") | Should -Match "Lenght of list differ|Ref has a value, but Diff is null"
            Compare-ObjectsExt ("foo", "bar", "baz") ("foo", "bar", "baz", "fed" ) | Should -Match "Lenght of list differ|Ref is null, but Diff has a value"
  
        }

        It "Returns expected output for hashes" {
            Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "bar"}) (@{ ID = 1; Name = "foo"; Description = "bar"})  | Should -BeNullOrEmpty 
            Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "baz"}) (@{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match ">> baz" 
            Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "baz"}) (@{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match "<< bar" 
            Compare-ObjectsExt (@{ ID = 1; Name = "foo"; Description = "baz"}) (@{ Name = "foo"; Description = "baz"; ID = 1})  | Should -BeNullOrEmpty

        }
    }
    Context "Comparision of objects consisting of simple types" {
        It "Returns expected output for composite objects" {
            Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  | Should -BeNullOrEmpty 
            Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "baz"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match ">> baz" 
            Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "baz"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  | Should -Match "<< bar" 
            Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "baz"}) (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = ("foo","bar")})   | Should -match "Ref and Diff datatype names differ"
        }
    }
    Context "Comparision of type differenies" {
        It "Notices difference between different data types" {
            Compare-ObjectsExt "foo" 1 | Should -Match '/ - Ref and Diff datatype names differ'
            Compare-ObjectsExt 2.533 1 | Should -Match '/ - Ref and Diff datatype names differ'
            Compare-ObjectsExt  ([char]'a') ([String]"a") | Should -Match '/ - Ref and Diff datatype names differ'
            Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"}) 1  | Should -Match '/ - Ref and Diff datatype names differ'
        }
    }
    Context "Comparision result for summary information" {
        It "provides correct summary information" {
            $result1 = Compare-ObjectsExt ((get-process)[0]) ((get-process)[2]) -ProvideStats 
            ((($result1 -match '^Diffs: ' -split ' ')[1] -replace ',' ) -eq ($result1 -match '^/').count ) | Should -BeTrue
            $result2 = Compare-ObjectsExt (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bar"})  (New-Object PSObject -Property @{ ID = 1; Name = "foo"; Description = "bark"}) -ProvideStats
            ((($result2 -match '^Diffs: ' -split ' ')[3] -replace ',' ) -eq "2" ) | Should -BeTrue
            ((($result2 -match '^Diffs: ' -split ' ')[5]) -eq "0" ) | Should -BeTrue

        }
    }
    Context "Help content available for all functions" {
        It "All functions has help content" {
            Get-Help Compare-ObjectsExt -Full | Should -Match "DESCRIPTION"
            Get-Help Compare-ObjectsExt -Full | Should -Match "https://github.com"
            Get-Help write-diff -Full | Should -Match "DESCRIPTION"
            Get-Help isSimpleType  -Full | Should -Match "DESCRIPTION"
            Get-Help isList -Full | Should -Match "DESCRIPTION"
            Get-Help isHash -Full | Should -Match "DESCRIPTION"
            Get-Help reachedMaxRecursionDepth -Full | Should -Match "DESCRIPTION"
            Get-Help Compare-ListThorough -Full | Should -Match "DESCRIPTION"
        }
    }
}

Describe -Tag 'Slow' "Handles bigger objcets read from files" {
    Context "Comparision of complex objects" {
        It "Compares xml objects correctly" {
            $xml1 = [xml](get-content ./testdata/test1.xml)
            $xml2 = [xml](get-content ./testdata/test2.xml)
            $result3 = Compare-ObjectsExt $xml1 $xml1 -ProvideStats 
            ((($result3 -split ' ')[1] -replace ',' ) -eq "0" ) | Should -BeTrue
            ((($result3 -split ' ')[3] -replace ',' ) -eq "391" ) | Should -BeTrue
            ((($result3 -split ' ')[5]) -eq "16" ) | Should -BeTrue
            $result4 = Compare-ObjectsExt $xml1 $xml2 -ProvideStats 
            ((($result4 -match '^Diffs: ' -split ' ')[1] -replace ',' ) -eq "12" ) | Should -BeTrue
            ((($result4 -match '^Diffs: ' -split ' ')[3] -replace ',' ) -eq "384" ) | Should -BeTrue
            ((($result4 -match '^Diffs: ' -split ' ')[5]) -eq "16" ) | Should -BeTrue
        }

        It "Compares json imported objects correctly" {
            $jsonobj1 = ConvertFrom-Json (get-content -raw ./testdata/test3.json)
            $jsonobj2 = ConvertFrom-Json (get-content -raw ./testdata/test4.json)
            $result5 = Compare-ObjectsExt $jsonobj1 $jsonobj1 -ProvideStats 
            ((($result5 -split ' ')[1] -replace ',' ) -eq "0" ) | Should -BeTrue
            ((($result5 -split ' ')[3] -replace ',' ) -eq "14" ) | Should -BeTrue
            ((($result5 -split ' ')[5]) -eq "0" ) | Should -BeTrue
            $result6 = Compare-ObjectsExt $jsonobj1 $jsonobj2 -ProvideStats 
            ((($result6 -match '^Diffs: ' -split ' ')[1] -replace ',' ) -eq "5" ) | Should -BeTrue
            ((($result6 -match '^Diffs: ' -split ' ')[3] -replace ',' ) -eq "9" ) | Should -BeTrue
            ((($result6 -match '^Diffs: ' -split ' ')[5]) -eq "0" ) | Should -BeTrue
        }
    }

} 
Describe "isSimpleType" {
    Context "Helper functions - isSimpleType" {
        It "returns true for simple types" {
            isSimpleType ("foo") | Should -BeTrue
            isSimpleType (1) | Should -BeTrue
            isSimpleType (1.2) | Should -BeTrue
            isSimpleType ("a",'b',"c") | Should -BeFalse
        }
    }
}

Describe "isList" {
    Context "Helper functions - isList" {
        It "returns true for list objects and false for simple objects" {
            isList ("foo") | Should -BeFalse
            islist ("a",'b',"c") | Should -BeTrue
        }
    }
}

Describe "isHash" {
    Context "Helper functions - isHash" {
        It "returns true for hash objects, but not for list or simple types" {
            isHash ("foo") | Should -BeFalse
            isHash ("a",'b',"c") | Should -BeFalse
            isHash ([ordered] @{foo = 1; bar = 2}) | Should -BeTrue
            isHash (@{foo = 1; bar = 2}) | Should -BeTrue
        }
    }
}
Describe "Write-Diff" {
    Context "Helper functions - Write-Diff" {
        It "returns text" {
            Write-Diff '/' "is ok" | Should -Match '/ - is ok'
        }
    }
}
Describe "reachedMaxRecursionDepth" {
    Context "Helper functions - reachedMaxRecursionDepth" {
        It "returns true for long paths and 4 or more elements with same name" {
            reachedMaxRecursionDepth "/.a.b.c.d.e" | Should -BeFalse
            reachedMaxRecursionDepth "/.a.b.c.d.e.e.e" | Should -BeFalse
            reachedMaxRecursionDepth "/.a.b.c.d.e.e.e.e" | Should -BeTrue
            reachedMaxRecursionDepth "/.a.a.a.b.b.b.c.c.c.d.d.d.e.e.e.f.f.f.g.g.g.h.h.h.i.i.i.j.j" | Should -BeFalse
            reachedMaxRecursionDepth "/.a.a.a.b.b.b.c.c.c.d.d.d.e.e.e.f.f.f.g.g.g.h.h.h.i.i.i.j.j.j" | Should -BeTrue
        }
    }
}
