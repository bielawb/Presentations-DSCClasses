#region authoring (DSC) classes
[DscResource()]
class Resource {}

[DscResource()]
class DefineMethods : Resource {
    [DefineMethods] Get () {
        return @{

        }
    }
    
    [bool] Test () {
        return $false
    }
    
    [void] Set () {

    }
}

[DscResource()] 
class KeyProperty : DefineMethods {
    [DscProperty(Key)]
    [String]$Key
    
    [DscProperty(Mandatory)]
    [String]$Required
    
    [DscProperty(NotConfigurable)]
    [String]$ReadOnly
    
    [DscProperty()]
    [String]$Write
}

#endregion

#region folder structure

Get-ChildItem -Path .\MyResource

Import-PowerShellDataFile -Path .\MyResource\MyResource.psd1

[System.Management.Automation.Language.Parser]::ParseFile(
    (Convert-Path -Path .\MyResource\MyResource.psm1),
    [ref]$null,
    [ref]$null
).FindAll(
    {
        $args[0] -is [System.Management.Automation.Language.TypeDefinitionAst]
    },
    $false
).Members | Select-Object -Property * -ExcludeProperty Parent, Extent

$hack = [scriptblock]::Create(@'
using module .\MyResource\MyResource.psd1
$out = [MyResource]@{
    MyKey = 'Key'
}
' --- GET ---'
$out.Get()
' --- TEST --'
$out.Test()
' --- SET ---'
$out.Set()
'@)
& $hack
#endregion