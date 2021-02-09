function Compare-ObjectsExt {
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
    return $testObject.gettype().Name -match '\[\]$'
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