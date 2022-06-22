#region Two types of classes
enum Tool {
    DSC
    Chef
    Puppet
    Ansible
    Salt
}

[Tool]::Puppet

class ToolBox {
    [Tool[]]$Tools
    [String]$Name
}

[ToolBox]::new()

#endregion

#region structure
class Foo {
    # Property
    [String]$Bar
    
    # Method
    [String] ShowBar () {
        return $this.Bar
    }
    
    # Constructor
    Foo ([String]$bar) {
        $this.Bar = $bar
    }
    
    # Default constructor - exist if we don't define others, worth defining otherwise
    Foo () {}
}

#endregion

#region Creating instances
[Foo]::new('Something')

$foo = [Foo]::new()
$foo.Bar = 'SomethingElse'
$foo.ShowBar()

[Foo]@{
    Bar = 'But...'
}

#endregion

#region Inheritance

class bar : foo {}
[bar]@{
    Bar = 'foo'
}

class DoubleUDoubleUDoubleU : System.Net.WebClient {
    [string] SaveToTemp ([String]$Address) {
        $temp = [io.path]::GetTempFileName()
        $this.DownloadFile($Address, $temp)
        return $temp
    }
}

$www = [DoubleUDoubleUDoubleU]::new()
$www.SaveToTemp('http://www.google.com') | Tee-Object -Variable googlePage
Get-Content -LiteralPath $googlePage -Tail 1

#endregion