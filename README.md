# Compare-ObjectsExt

Note that this is still a work in progress mainly consisting of this readme file for the moment!

The aim for Compare-ObjectsExt is to create a PowerShell script that can 
compare arbitary PowerShell objects, outputting where the differences are, in a easy to understand way.

This project consists of a PowerShell script and a Pester test script.

Like the built in version of Compare-Object, the script takes two mandatory arguments, $ref and $dif. In contrast to the built in version it does not rely on methods in the objects or any ToString() function to do the comparision.

## Usage: 

        git clone https://github.com/aaspnas/Compare-Objects.git
        cd Compare-Objects
        .\Compare-ObjectsExt.ps1
        Compare-ObjectsExt $obj1 $obj2

The script has help contents that can be viewed by:
 
        Get-Help Compare-ObjectsExt

## How will objects differ

Objects can differ in several ways:
- Value can be different, one value can even be null...
- Type can be different, and type is not allways self evident
- Lists of objects can differ
- Hash content can differ
- Properites, ScriptProperties, NoteProperties or PropertySets can differ
- Method names can differ
- Method signatures can differ

Objects can also contain other objects.  Some methods can create new objects, but as we generally dont know what the side effects of calling methods on a object will be, we can't go calling all methods systematically or? Properties with names starting "^PS" seems to be recursive objects that 
will cause an infinite loo, so we exclude those.

Simple values are directly compared with -eq. List length as well as the element at each position are compared. Note that if order in a list is different, the lists are considered to be different. An element missing in the middle of the list will cause the end of the list to mismatch. This will produce two differences to be output... Lists are recognixed from the object name having [] appended or type name being collection or ArrayList... There may be others as well in the future.

Hash tables are compared by number of keys and the value for each key. 

## References

- https://docs.microsoft.com/en-us/powershell/module/microsoft.powershell.core/?view=powershell-7.1