<#
    .Synopsis
    Compare-ObjectsExt compares two arbitrary PowerShell objects 

    .Description
    Compare-ObjectsExt compares two arbitrary objects and outputs 
    the difference on a detailed level. Like the built in version of 
    Compare-Object, the script takes two mandatory arguments, $ref and 
    $dif. In contrast to the built in version it does not rely on 
    methods in the objects or any ToString() function to do the 
    comparison.

    The script is released under GPL-3.0 License. Please see the License 
    file in the distribution for details.  

    See the link below where to obtain the latest version, submit issues etc...

    .Link
    https://github.com/aaspnas/Compare-Objects

    .Example
    cd Compare-Objects;
    .\Compare-ObjectsExt.ps1;
    Compare-ObjectsExt $obj1 $obj2;

    See the README.md file and the Test file for more examples.

    .Parameter Ref
    Reference object for comparison

    .Parameter Diff
    Object to compare against

    .Parameter Path
    Path should left empty on invocation or set to '/', but will be used when 
    recursing the objects structure to indicate the depth and object properties. 
    If you want to obtain a copy paste ready path to the differing property you can 
    set the value to the objects variable name like '$obj1', but this will cause 
    ProvideStats flag to fail...

    .Parameter ProvideStats
    Provide numeric detail output of matches in addition to only the differences. 
    The values provide the number of differences, the number of matches and the number 
    of times the traversal of the object tree encountered a situation interpreted as 
    endless recursion.


    .Notes
    AUTHOR:  Anders Aspnäs - https://github.com/aaspnas/Compare-Objects
    VERSION: 1.0.1 - See github for commit history
    License: GPL-3 - See license file in the distribution, or github
    SPDX-License-Identifier: GPL-3.0-or-later

#>
function Compare-ObjectsExt {
    # Public function to compare two arbitrary objects 
    Param(
    [Parameter(Position=0, 
    Mandatory=$true)]
    [AllowEmptyString()]
    [Alias('Reference')]
    [AllowNull()]
    $ref,

    [Parameter(Position=1, 
    Mandatory=$true)]
    [AllowEmptyString()]
    [Alias('Difference')]
    [AllowNull()]
    $diff,

    [Parameter(Mandatory=$false)]
    [String[]] 
    $path ='/',

    [Parameter(Mandatory=$false)]
    [Switch]
    $ProvideStats
)


    if (reachedMaxRecursionDepth $path) {
        ## Going too deep...
        return
    }
    if ($path -eq '/') {
        ## Set start values for counters
        $Global:diffCount = 0
        $Global:similarCount = 0
        $Global:maxRecursionDepthExceeded = 0
    }
    if ($null -eq $ref -or '' -eq $ref) { 
        ## Handle null values
        if ($null -eq $diff -or '' -eq $diff) {
            $Global:similarCount++
            Write-debug ("Similar at $path - " + $global:similarCount)
            return 
        } else {
            Write-Diff $path "Ref is null, but Diff has a value"
            return 
        }
    } else {
        if ($null -eq $diff -or '' -eq $diff) {
            Write-Diff $path "Ref has a value, but Diff is null"
            return

        } 
    }
    Write-Debug "Ref and diff both not null"
    $refTypeData = $ref.GetType().Name
    $diffTypeData = $diff.GetType().Name

    Write-Debug "Ref type: $refTypeData, Diff type: $diffTypeData"

    if ($null -eq $refTypeData) {
        if ($null -eq $diffTypeData) {
            # Datatype match $null, impossible situation
            Write-Debug "Ref and Diff data type null"

        } else {
            # Datatype match $null, impossible situation
            Write-Diff $path "Ref: Ref data type is null, but Diff data type has a value"
            return
        }
    } else {
        if ($null -eq $refTypeData) {
            # Datatype match $null, impossible situation
            Write-Diff $path "Ref: Diff data type is null, but Ref data type has a value"
            return
        } else {
           
            if ($refTypeData -eq $diffTypeData) {
                # looks promising, now we can examine objects
                if (isSimpleType($ref)) {
                    if ($ref -eq $diff) {
                        $Global:similarCount++
                        Write-debug ("Similar at $path - " + $global:similarCount)
                        return
                    } else {
                        Write-Diff "$path`n"  ">> $ref `n - << $diff"  
                    }

                } elseif (isList($ref)) {
                    ## This is a quick comparison of the lists, the beginning to 
                    ## a more thorough analysis can be found as work in progress 
                    ## in Compare-ListThorough
                    $additionaldiffs = @()
                    if ($ref.Count -ne 0) {
                        if ($ref.Count -ne $diff.Count) {
                            write-Diff $path ("Length of list differ: Ref: " + $ref.count + ",  Diff: " + $diff.count)   
                            if ($diff.Count -gt $ref.Count) {
                                $additionaldiffs = ($diff | Where-Object { $_ -notin $ref })
 
                            }
                        }
                        
                        $i = 0;
                        ## $ref = ($ref | Sort-Object)
                        ## $diff = ($diff | Sort-Object)
                        foreach ($o in $ref) {
                            $listPath = "$path[$i]"
                            Compare-ObjectsExt -ref $o -diff ($diff[$i]) -path $listPath
                            $i++
                        } 
                        foreach ($o in $additionaldiffs) {
                            $listPath = "$path[$i]"
                            Compare-ObjectsExt -ref ($ref[$i]) -diff $o -path $listPath
                            $i++
                        }

                    } else {
                        if ($diff.Count -ne 0) {
                            write-Diff $path "Ref is null and Diff list contain values"

                        }
                    }
                } elseif (isHash($ref)) {
                    $refKeys = $ref.Keys
                    $diffKeys = $diff.Keys
                    $additionalKeys = @()
                    if ($refKeys.Count -ne 0) {
                        if ($refKeys.Count -ne $diffKeys.Count) {
                            if ($diffKeys.Count -gt $refKeys.Count) {
                                $additionalKeys = ($diffKeys | Where-Object { $_ -notin $refKeys })
                            }
                            write-Diff $path "Ref and Diff hashes contain different number of keys"
                        }
                        foreach ($k in $refKeys) {
                            $hashPath = "$path[$k]"
                            Compare-ObjectsExt -ref ($ref[$k]) -diff ($diff[$k]) -path $hashPath
                        }
                        foreach ($k in $additionalKeys) {
                            $hashPath = "$path[$k]"
                            Compare-ObjectsExt -ref ($ref[$k]) -diff ($diff[$k]) -path $hashPath
                        }
                    } else {
                        if ($diffKeys.Count -ne 0) {
                            write-Diff $path "Ref is null and Diff hash contains keys"
                        }
                    }
                } else {
                    ## Seems we have an actual object here...
                    $refMembers = ($ref | get-member | Where-Object {$_.MemberType -match 'Property' -and $_.Definition -notmatch '{set;}'}) 
                    $diffMembers = ($diff | get-member | Where-Object {$_.MemberType -match 'Property' -and $_.Definition -notmatch '{set;}'} | Where-Object { $_.Name -notin $refMembers.Name })
                    if (($null -ne $diffMembers) -and ($diffMembers.Count -gt 0)) { 
                        $allMembers = $refMembers + $diffMembers
                    } else {
                        $allMembers = $refMembers
                    }
                    foreach ($s in ($allMembers.Name)) {
                        [string]$objPath = "$path" + '.' + "$s"
                        Write-debug "Object - traversal - $objPath"

                        Compare-ObjectsExt -ref ($ref.$s) -diff ($diff.$s) -path ($objPath)
                    } 
                }

            } else {
                Write-Diff $path "Ref and Diff datatype names differ"
            }

        }
    }

    if (($path -eq '/') -and ($ProvideStats)) {
        $message = "Diffs: $Global:diffCount, Matches: $Global:similarCount, RecursionLimitExceeded: $Global:maxRecursionDepthExceeded"
        Write-Output $message
    }
}

function Write-Diff {
    <#
    .SYNOPSIS
    Output difference between objects
    
    .DESCRIPTION
    Private function to output for differences between objects
    
    .PARAMETER locationPath
    Location in object where difference occurred
    
    .PARAMETER diffMessage
    Message conveying what the difference was
    
    .EXAMPLE
    Write-Diff $path $message
    
    .NOTES
    The format is still subject to change and use has not been implemented everywhere...
    #>
    param (
        $locationPath,

        $diffMessage
    )
    $Global:diffCount++
    Write-Output "$locationPath - $diffMessage"

}

function isSimpleType {
    # Private function to deduce whether object given as argument
    # is of a type we can easily compare with a simple -eq
    param (
        $testObject
    )
    $types = @("string", "char", "byte", "int", "int32", "int64", "long", "bool", "decimal", "single", "double")

    return ($testObject.GetType().Name -in $types)
}

function isList {
    <#
    .SYNOPSIS
    Return true if parameter is a list
    
    .DESCRIPTION
    Private function to deduce whether object given as argument
    is a list.
    
    .PARAMETER testObject
    Object to inspect
    
    .EXAMPLE
    isList $obj
    
    .NOTES
    Currently object type is compared to [], ArrayList or collection, but may need to be amended
    #>
    param (
        $testObject
    ) 
    if (($testObject.gettype().Name -match '\[\]$') -or `
        ($testObject.gettype().Name -match 'ArrayList') -or `
        ($testObject.gettype().Name -match 'collection')) {
        return $true
    } else {
        return $false
    }
}

function isHash {
    <#
    .SYNOPSIS
    Return true if parameter passed to the function is a hash table 
    
    .DESCRIPTION
    Private function to deduce whether object given as argument
    is a hash table with key and value pairs.
    
    .PARAMETER testObject
    Object to inspect
    
    .EXAMPLE
    isHash $obj
    
    .NOTES
    May need to be amended with additional hash table object names in $types below
    #>

    param (
        $testObject
    )
    $types = @("Hashtable", "OrderedDictionary")

    return ($testObject.GetType().Name -in $types)

}

function reachedMaxRecursionDepth {
    <#
    .SYNOPSIS
    Internal function that return true if we are going too deep
    
    .DESCRIPTION
    Return true if we are going too deep according to $env:CompareObjectMaxDepth (or default 
    setting of 30) or if same property name occurs 4 or more times in the path. The function is 
    intended for internal use.
    
    .PARAMETER locationPath
    Path in the object for the property we are at
    
    .EXAMPLE
    reachedMaxRecursionDepth $path
    
    .NOTES
    Splitting of the path is done based on the . char. There is no limit on list lengths or 
    number of elements in a hash. 
    #>
    param (
        $locationPath
    )

    $pathList = $locationPath.split('.')
    Write-Debug ("path is " + $pathList.count + " long")
    if ($pathList.Count -gt $Global:maxComparisonDepth) {
        Write-Debug "Max depth reached for object at $locationPath"
        $Global:maxRecursionDepthExceeded++
        return $true
    }
    if (($pathList[-1] -eq $pathList[-2]) -and `
        ($pathList[-1] -eq $pathList[-3]) -and `
        ($pathList[-1] -eq $pathList[-4])) {
        Write-Debug "Recursion detected for object at $locationPath"
        $Global:maxRecursionDepthExceeded++
        return $true
    }
    return $false
}
function Compare-ListThorough {
    <#
    .SYNOPSIS
    More thorough comparison of two lists, $ref and $arg, not in use
    
    .DESCRIPTION
    Internal function for comparing two lists, currently not used

    .PARAMETER ref
    Reference list to compare against
    
    .PARAMETER diff
    Difference to compare with Ref
    
    .PARAMETER path
    Path in object where  we are, like /Property.List[2]
    
    .EXAMPLE
    Compare-ListThorough $list1 $list2
    
    .NOTES
    Experimental, only for test use, probably does not work yet
    #>
    Param(
        [Parameter(Position=0, 
        Mandatory=$true)]
        [AllowEmptyString()]
        [Alias('Reference')]
        [AllowNull()]
        $ref,
    
        [Parameter(Position=1, 
        Mandatory=$true)]
        [AllowEmptyString()]
        [Alias('Difference')]
        [AllowNull()]
        $diff,
    
        [Parameter(Mandatory=$false)]
        [String[]] 
        $path ='/'
    )
    [System.Collections.ArrayList]$result = @()
    foreach ($o in $ref) {
        [System.Collections.ArrayList]$compResult = @()
        $x = 0
        $listPath = "$path[$i]"
        foreach ($d in $diff) {
            $dl = (Compare-ObjectsExt -ref ($o) -diff ($d) -path $listPath)
            if ($dl -eq "") {
                Write-Debug "Element $i matches $x - match found"
            }
            $compResult.Add($dl) | Out-Null
            $x++
        }
        $result.Add($compResult) | Out-Null
        # Write-Output $dr
        $i++
    }
    ## Analysis done, now we need to figure out what matches

}

<#
    .Synopsis
    Dump printable content from an object

    .Description
    Dumps content from the object 

    .Example
    Dump-Object $foo

    .Parameter Obj
    Reference object to dump

    .Parameter Path
    Not for external use, only for recursion

    .Notes
    Utility function to see what properties we see in an object.
#>
function Dump-Object {
    # Public function to dump viewable content of the object
    Param(
    [Parameter(Position=0, 
    Mandatory=$true)]
    [AllowEmptyString()]
    [Alias('Object')]
    [AllowNull()]
    $obj,

    [Parameter(Mandatory=$false)]
    [String[]] 
    $path ='/'
    )
    if (reachedMaxRecursionDepth $path) {
        ## Going too deep...
        return
    }
    if ($path -eq '/') {
    }
    if ($null -eq $obj) { 
        ## Handle null values
        Write-Dump $path "null"
    } else {
        $objTypeData = $obj.GetType().Name
        if ($null -eq $objTypeData) {
            Write-Dump $path "Data type null"
        } else {
            if (isSimpleType($obj)) {
                Write-debug ("writing actual value")
                Write-Dump $path $obj
                return
            } elseif (isList($obj)) {                        
                $i = 0;
                foreach ($o in $obj) {
                    $listPath = "$path[$i]"
                    Dump-Object -obj $o -path $listPath
                    $i++
                } 
            } elseif (isHash($obj)) {
                $objKeys = $obj.Keys
                if ($objKeys.Count -ne 0) {
                    foreach ($k in $objKeys) {
                        $hashPath = "$path[$k]"
                        Dump-Object -obj ($obj[$k]) -path $hashPath
                    }
                }
            } else {
                ## Seems we have an actual object here...
                $objMembers = ($obj | get-member | Where-Object {$_.MemberType -match 'Property' -and $_.Definition -notmatch '{set;}'}) 
                foreach ($s in ($objMembers.Name)) {
                    [string]$objPath = "$path" + '.' + "$s"
                    Write-debug "Object - traversal - $objPath"
                    Dump-Object -obj ($obj.$s) -path ($objPath)
                }
            }
        }
    }
}


function Write-Dump {
    <#
    .SYNOPSIS
    Output objects
    
    .DESCRIPTION
    Private function to output objects
    
    .PARAMETER locationPath
    Location in object 
    
    .PARAMETER value
    Value of the object
    
    .EXAMPLE
    Write-Dump $path $value
    
    .NOTES
    The format is still subject to change and use has not been 
    implemented everywhere...
    #>
    param (
        $locationPath,

        $value
    )
    Write-Output "$locationPath = $value"

}


### Main method
## Read from Env
$Global:maxComparisonDepth = 30
if ($env:CompareObjectMaxDepth){
    $Global:maxComparisonDepth = $env:CompareObjectMaxDepth
}

## Global variables

$Global:maxRecursionDepthExceeded = 0
$Global:diffCount = 0
$Global:similarCount = 0    

## Handle arguments passed on script invocation
$scriptRef=$args[0]
$scriptDiff=$args[1]

if (($scriptRef) -and ($scriptDiff)) {
    Compare-ObjectsExt $scriptRef $scriptDiff
}