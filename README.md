# Compare-ObjectsExt

The aim for Compare-ObjectsExt is to create a PowerShell script that can 
compare arbitary PowerShell objects, outputting where the differences are, in a easy to understand way.

This project consists of a PowerShell script and a Pester test script.

Like the built in version of Compare-Object, the script takes two mandatory arguments, $reference and $difference. In contrast to the built in version it does not rely on methods in the objects or any ToString() function to do the comparision.

Usage: Compare-ObjectsExt $obj1 $obj2

