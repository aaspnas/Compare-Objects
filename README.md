# Compare-ObjectsExt

The aim for Compare-ObjectsExt is to create a PowerShell script that can 
compare arbitary PowerShell objects, outputting where the differences are, 
in a easy to understand way.

The built in Compare-Object function does not always provide useful output, 
for example when comparing custom PSObjects, XML stuctures or JSON imported
data. Compare-ObjectsExt aims to address these shortcommings.

This project consists of a PowerShell script and a Pester test script.

Like the built in version of Compare-Object, the script takes two mandatory 
arguments, $ref and $dif. In contrast to the built in version it does not rely 
on equals methods in the objects or any ToString() function to do the comparision.
In stead we examine recursively every node in the object, Property by property, 
Hash key value to hash key value, list element to list element against each others. 

## Usage: 

```
        git clone https://github.com/aaspnas/Compare-Objects.git
        cd Compare-Objects
        .\Compare-ObjectsExt.ps1
        Compare-ObjectsExt $obj1 $obj2
```

or if you perfer

```
        .\Compare-ObjectsExt.ps1 $obj1 $obj2

```

Compare-ObjectsExt can be used to compare xml documents:

```
        .\Compare-ObjectsExt.ps1
        Compare-ObjectsExt ([xml](get-content ./testdata/test1.xml)) ([xml](get-content ./testdata/test1.xml)) 
```

Compare-ObjectsExt can be used to compare json documents:

```
Compare-ObjectsExt (ConvertFrom-Json (gc -raw ./testdata/test3.json)) (ConvertFrom-Json (gc -raw ./testdata/test3.json))   
```

The script has help contents that can be viewed by:

``` 
        Get-Help Compare-ObjectsExt
```

## How will objects differ

Objects can differ in several ways:
- Value can be different, one value can even be null...
- Type can be different, and type may not allways self evident
- Lists of objects can differ in several ways, containign different number 
  of elements, being null, elements being of different type, elements having 
  different value, elements being in different order
- Hash content can differ by one being null, different type, different number 
  of keys, different values. 
- Properites, ScriptProperties, NoteProperties or PropertySets can differ in an
  object
- Method names of an object can differ (not considered)
- Method signatures of an object can differ (not considered)

Objects can also contain other objects.  Some methods can create new objects, 
but as we generally dont know what the side effects of calling methods on an 
object will be, we can't go calling all methods systematically or? Feel free 
to try to change my mind, but currently the script ignores any methods.

Properties can hold recursive objects that may cause an infinite loops, so we 
exclude those. It is difficult to know when an object contains a property pointing 
back to a parent object, or otherwise contain endless lists of properties pointing 
to object in an infinite chain. The script will limit the recursion performed to a 
default max of 30 levels, or a set of 4 properties with the same name in a chain 
(eg $ref.Value.Value.Value.Value). The max level can be set by modifying the 
environment variable $env:CompareObjectMaxDepth. 

Simple values are directly compared with -eq. List length as well as the element 
at each position are compared. Note that if order in a list is different, the lists 
are considered to be different. An element missing in the middle of the list will 
cause the end of the list to mismatch. This will produce two differences to be 
output... Lists are recognized from the object name having [] appended or type name 
being collection or ArrayList... There may be others as well in the future. When 
comparing a list to another the order of elements is considered, although this may 
be subject to change in the future...

Hash tables are compared by number of keys and the value for each key. The order of 
elements in a Hash should not affect the result.

## Testing

The functionality is tested by the Pester script in this distribution. For more 
information on testing with Pester and installing the Pester test framework please 
see the reference at the bottom of this page. More tests could certainly be added, 
and some tests execute a bit slow (comparing xml for example).

If you wish to run the tests you can do so by executing:

```
    Invoke-Pester ./Compare-ObjectsExt.Tests.ps1 -ExcludeTagFilter "Slow"
```

 or for all tests: 

```
    Invoke-Pester ./Compare-ObjectsExt.Tests.ps1
```
 or with detailed results:

```
    Invoke-Pester ./Compare-ObjectsExt.Tests.ps1 -Output Detailed
```

All tests should pass, if not feel free to open a ticket.

Testing has not been done on any old versions of PowerShell, so updating to the 
latest version would be recommended.

## References

Powershell Reference:     https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/?view=powershell-7.1
 
Pester reference wiki:    https://github.com/pester/Pester/wiki
 