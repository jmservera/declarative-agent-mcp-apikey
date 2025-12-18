param(
    [Parameter(Mandatory=$true, Position=0)]
    [string]$FilePath,
    
    [Parameter(Mandatory=$true)]
    [string[]]$Properties
)

function Remove-PropertiesRecursive {
    param(
        [Parameter(Mandatory=$true)]
        $Object,
        
        [Parameter(Mandatory=$true)]
        [string[]]$PropertiesToRemove
    )
    
    if ($null -eq $Object) {
        return $null
    }
    
    # Handle PSCustomObject (from ConvertFrom-Json)
    if ($Object -is [PSCustomObject]) {
        $newObject = [PSCustomObject]@{}
        
        foreach ($property in $Object.PSObject.Properties) {
            if ($PropertiesToRemove -notcontains $property.Name) {
                $newObject | Add-Member -MemberType NoteProperty -Name $property.Name -Value (Remove-PropertiesRecursive -Object $property.Value -PropertiesToRemove $PropertiesToRemove)
            }
        }
        
        return $newObject
    }
    # Handle arrays
    elseif ($Object -is [System.Array] -or ($Object -is [System.Collections.IEnumerable] -and $Object -isnot [string])) {
        $newArray = @()
        foreach ($item in $Object) {
            $newArray += Remove-PropertiesRecursive -Object $item -PropertiesToRemove $PropertiesToRemove
        }
        return ,$newArray  # Comma ensures array is not unwrapped
    }
    # Handle primitive types (strings, numbers, booleans, etc.)
    else {
        return $Object
    }
}

# Validate file exists
if (-not (Test-Path $FilePath)) {
    Write-Error "File not found: $FilePath"
    exit 1
}

# Read JSON file as PSCustomObject (not hashtable) to preserve types
$jsonContent = Get-Content -Path $FilePath -Raw | ConvertFrom-Json

# Remove specified properties recursively
$modifiedContent = Remove-PropertiesRecursive -Object $jsonContent -PropertiesToRemove $Properties

# Convert back to JSON with proper formatting and preserve arrays
$jsonOutput = $modifiedContent | ConvertTo-Json -Depth 100 -Compress:$false

# Write back to file
$jsonOutput | Set-Content -Path $FilePath -NoNewline

Write-Host "Successfully removed properties: $($Properties -join ', ') from $FilePath"
