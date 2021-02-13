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

    .Parameter Ref
    Reference objet for comparison

    .Parameter Diff
    Object to compare against

    .Parameter Path
    Path is normaly left empty on invocation, but will be used when recursing
    the objects structure to indicate the depth and object properties. If you 
    want to obtain a copy paste ready path to the differing property you can 
    set the value to the objects variable name like '$obj1'. 

    .Parameter NoDetails
    Supress detail output (probably not yet implemented)
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
    $NoDetails
)

    if ($null -eq $ref -or '' -eq $ref) { 
        if ($null -eq $diff -or '' -eq $diff) {
            return 
        } else {
            return "$path - Ref is null, but Diff has a value not null"
        }
    } else {
        if ($null -eq $diff -or '' -eq $diff) {
            return "$path - Ref is not null, but Diff has a null value"

        } else {
        
        }
    }
    Write-Debug "ref and diff both not null"
    $refTypeData = ($ref | Get-TypeData).TypeNames
    $diffTypeData = ($diff | Get-TypeData).TypeNames

    if ($null -eq $refTypeData) {
        $refTypeData = $ref.GetType().Name
    }

    if ($null -eq $diffTypeData) {
        $diffTypeData = $diff.GetType().Name
    }
    Write-Debug "Ref type:"
    Write-Debug "$refTypeData"
    Write-Debug "Diff type:"
    write-Debug "$diffTypeData"

    if ($null -eq $refTypeData) {
        if ($null -eq $refTypeData) {
            # Datatype match $null, impossible situation
        } else {
            # Datatype match $null, impossible situation
            return "$path - Ref: Ref data type is null, but Diff data type has a value not null"
        }
    } else {
        if ($null -eq $refTypeData) {
            # Datatype match $null, impossible situation
            return "$path - Ref: Diff data type is null, but Ref data type has a value not null"

        } else {
           
            if ($refTypeData -eq $diffTypeData) {
                # looks promising, now we can examine objects
                if (isSimpleType($ref)) {
                    if ($ref -eq $diff) {
                        return
                    } else {
                        Write-Diff "$path`n"  ">> $ref `n - << $diff"  
                    }

                } elseif (isList($ref)) {
                    ## This is a quick omparision of the lists, the beginning to 
                    ## a more thorough analysis can be found in Compare-ListThorough
                    if ($ref.Count -ne 0) {
                        if ($ref.Count -ne $diff.Count) {
                            write-Diff $path "Ref and Diff list lenght differ"
                        }
                        $i = 0;
                        ## $ref = ($ref | Sort-Object)
                        ## $diff = ($diff | Sort-Object)
                        foreach ($o in $ref) {
                            $listPath = "$path[$i]"
                            Compare-ObjectsExt -ref $o -diff ($diff[$i]) -path $listPath
                            $i++
                        }
                    } else {
                        if ($diff.Count -ne 0) {
                            write-Diff $path "Ref is null and Diff list contain values"

                        }
                    }
                } elseif (isHash($ref)) {
                    $refkeys = $ref.Keys()
                    $diffkeys = $diff.Keys()
                    if ($refkeys.Count -ne 0) {

                    
                        if ($refkeys.Count -ne $diffkeys.Count) {

                            write-Diff $path "Ref and Diff hashes contain diferent number of keys"
                        }
                        foreach ($k in $refkeys) {
                            $hashpath = "$path[$k]"
                            Compare-ObjectsExt -ref ($ref[$k]) -diff ($diff[$k]) -path $hashpath
                        }
                    } else {
                        if ($diffkeys.Count -ne 0) {
                            write-Diff $path "Ref is null and Diff hashes contain values"

                        }
                    }
                } else {
                    ## Seems we have an actual object here...
                    $refmembers = ($ref | get-member | Where-Object -Property MemberType -match 'Property') 
                    # $diffmembers = ($diff | get-member | Where-Object -Property MemberType -match 'Property')
                    foreach ($s in ($refmembers.Name)) {
                        if ($s -match "^PS") {
                            write-debug "Avoiding PS* properties as these can be recursive"
                        } else {
                            [string]$objpath = "$path" + '.' + "$s"
                            Write-debug "Object - traversal - $objpath"

                            Compare-ObjectsExt -ref ($ref.$s) -diff ($diff.$s) -path ($objpath)
                        }
                    } 
                }

            } else {
                return "$path - Ref and Diff datatype names differ"
            }

        }
    }

    
}

function Write-Diff {
    # private function to output for differencies between objects
    # Note that this is still subject to change
    param (
        $locationPath,

        $diffMessage,

        $breakHere
    )
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
    # Private function to deduce wherther object given as argument
    # is a list
    param (
        $testObject
    ) 
    if (($testObject.gettype().Name -match '\[\]$') -or ($testObject.gettype().Name -match 'ArrayList') -or ($testObject.gettype().Name -match 'collection')) {
        return $true
    } else {
        return $false
    }
}

function isHash {
    # Private function to deduce wherther object given as argument
    # is a hash table
    param (
        $testObject
    )
    $types = @("Hashtable", "OrderedDictionary")

    return ($testObject.GetType().Name -in $types)

}

function Compare-ListThorough {
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
        $NoDetails
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