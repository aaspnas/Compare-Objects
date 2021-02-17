<#
    .Synopsis
    Compare-ObjectsExt compares two arbitary objects 

    .Description
    Compare-ObjectsExt compares two arbitary objects and outputs 
    the difference on a detailed level. Like the built in version of 
    Compare-Object, the script takes two mandatory arguments, $ref and 
    $dif. In contrast to the built in version it does not rely on 
    methods in the objects or any ToString() function to do the 
    comparision.

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
    Reference objet for comparison

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
    VERSION: 1.0.0 - See github for commit history
    License: GPL-3 - See license file in the distribution, or github

#>
function Compare-ObjectsExt {
    # Public function to compare two arbitary objects 
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
                        return
                    } else {
                        Write-Diff "$path`n"  ">> $ref `n - << $diff"  
                    }

                } elseif (isList($ref)) {
                    ## This is a quick comparision of the lists, the beginning to 
                    ## a more thorough analysis can be found as work in progress 
                    ## in Compare-ListThorough
                    $additionaldiffs = @()
                    if ($ref.Count -ne 0) {
                        if ($ref.Count -ne $diff.Count) {
                            write-Diff $path ("Lenght of list differ: Ref: " + $ref.count + ",  Diff: " + $diff.count)   
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
                    $refkeys = $ref.Keys
                    $diffkeys = $diff.Keys
                    $additionalkeys = @()
                    if ($refkeys.Count -ne 0) {
                        if ($refkeys.Count -ne $diffkeys.Count) {
                            if ($diffkeys.Count -gt $refkeys.Count) {
                                $additionalkeys = ($diffkeys | Where-Object { $_ -notin $refkeys })
                            }
                            write-Diff $path "Ref and Diff hashes contain diferent number of keys"
                        }
                        foreach ($k in $refkeys) {
                            $hashpath = "$path[$k]"
                            Compare-ObjectsExt -ref ($ref[$k]) -diff ($diff[$k]) -path $hashpath
                        }
                        foreach ($k in $additionalkeys) {
                            $hashpath = "$path[$k]"
                            Compare-ObjectsExt -ref ($ref[$k]) -diff ($diff[$k]) -path $hashpath
                        }
                    } else {
                        if ($diffkeys.Count -ne 0) {
                            write-Diff $path "Ref is null and Diff hash contains keys"
                        }
                    }
                } else {
                    ## Seems we have an actual object here...
                    $refmembers = ($ref | get-member | Where-Object -Property MemberType -match 'Property') 
                    $diffmembers = ($diff | get-member | Where-Object -Property MemberType -match 'Property' | Where-Object { $_.Name -notin $refmembers.Name })
                    if (($null -ne $diffmembers) -and ($diffmembers.Count -gt 0)) { 
                        $allmembers = $refmembers + $diffmembers
                    } else {
                        $allmembers = $refmembers
                    }
                    foreach ($s in ($allmembers.Name)) {
                        [string]$objpath = "$path" + '.' + "$s"
                        Write-debug "Object - traversal - $objpath"

                        Compare-ObjectsExt -ref ($ref.$s) -diff ($diff.$s) -path ($objpath)
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
    Private function to output for differencies between objects
    
    .PARAMETER locationPath
    Location in object where difference occured
    
    .PARAMETER diffMessage
    Message convaying what the difference was
    
    .EXAMPLE
    Write-Diff $path $message
    
    .NOTES
    The format is still subject to change and use has not been implemnted everywhere...
    #>
    param (
        $locationPath,

        $diffMessage
    )
    $Global:diffCount++
    Write-Output "$locationPath - $diffMessage"

}

function isSimpleType {
    # Private function to deduce wherther object given as argument
    # is of a type we can easily compare with a simple -eq
    param (
        $testObject
    )
    $types = @("string", "char", "byte", "int", "int32", "long", "bool", "decimal", "single", "double")

    return ($testObject.GetType().Name -in $types)
}

function isList {
    <#
    .SYNOPSIS
    Return true if parameter is a list
    
    .DESCRIPTION
    Private function to deduce wherther object given as argument
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
    Private function to deduce wherther object given as argument
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
    setting of 30) or if same property name occure 4 or more times in the path. The function is 
    intended for internal use.
    
    .PARAMETER locationPath
    Path in the object for the property we are at
    
    .EXAMPLE
    reachedMaxRecursionDepth $path
    
    .NOTES
    Splitting of the path is done based on the . char.
    #>
    param (
        $locationPath
    )

    $pathList = $locationPath.split('.')
    Write-Debug ("path is " + $pathList.count + " long")
    if ($pathList.Count -gt $Global:maxComparisionDepth) {
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
    More thorough comparision of two lists, $ref and $arg, not in use
    
    .DESCRIPTION
    Internal function for comparing two lists, currently not used

    .PARAMETER ref
    Referene list to compare against
    
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
        [System.Collections.ArrayList]$compresult = @()
        $x = 0
        $listPath = "$path[$i]"
        foreach ($d in $diff) {
            $dl = (Compare-ObjectsExt -ref $o -diff ($d) -path $listPath)
            $compresult.Add($dl) | Out-Null
            $x++
        }
        $result.Add($compresult) | Out-Null
        # Write-Output $dr
        $i++
    }
    ## Analysis done, now we need to figure out what matches

}

### Main method
## Read from Env
$Global:maxComparisionDepth = 30
if ($env:CompareObjectMaxDepth){
    $Global:maxComparisionDepth = $env:CompareObjectMaxDepth
}

## Global variables

$Global:maxRecursionDepthExceeded = 0
$Global:diffCount = 0
$Global:similarCount = 0    

## Hande arguments passed on script invokation
$scriptref=$args[0]
$scriptdiff=$args[1]

if (($scriptref) -and ($scriptdiff)) {
    Compare-ObjectsExt $scriptref $scriptdiff
}