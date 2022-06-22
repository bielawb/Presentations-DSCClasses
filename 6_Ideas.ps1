#region base class with useful methods, share between resources.

class baseModule {
    [void] ImportModule () {
        Import-Module -Name ForMyResource -Verbose:$false
    }

    [void] ReportIssue (
        [String]$Message,
        [String]$Level
    ) {
        switch ($Level) {
            Error {
                Write-Error -Message $Message
                Write-EventLog -Message $Message -EntryType Error -LogName 'Windows PowerShell' -Source myResource -EventId 404
            }
            Verbose {
                Write-Verbose -Message $Message
                Write-EventLog -Message $Message -EntryType Information -LogName 'Windows PowerShell' -Source myResource -EventId 202
            }
            Warning {
                Write-Warning -Message $Message
                Write-EventLog -Message $Message -EntryType Warning -LogName 'Windows PowerShell' -Source myResource -EventId 301
            }
            default {
                Write-Information -MessageData $Message
            }
        }
    }

    [void] WriteError (
        [String]$Message
    ) {
        $this.ReportIssue($Message, 'Error')
    }

    [void] WriteVerbose (
        [String]$Message
    ) {
        $this.ReportIssue($Message, 'Verbose')
    }

    [void] WriteWarning (
        [String]$Message
    ) {
        $this.ReportIssue($Message, 'Warning')
    }

    [void] WriteWarning (
        [String]$Message,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    ) {
        $formattedMessage = @"
{0}: {1} ({2})
Details:
{3}
"@ -f @(
            $Message,
            $ErrorRecord.Exception.Message,
            $ErrorRecord.FullyQualifiedErrorId
            $ErrorRecord.ScriptStackTrace
        )
        $this.ReportIssue($formattedMessage, 'Warning')
    }

}

[DscResource()]
class realResource : baseModule {
    [DscProperty(Key)]
    [String]$MyKey

    [DscProperty()]
    [String]$Writeable

    [realResource] Get () {
        try {
            $this.ImportModule()
            $value = Get-Something -Foo $this.MyKey
        } catch {
            $value = $null
            $this.WriteVerbose("Something went wrong in Get - $_")
            $this.WriteWarning("Something went wrong in Get", $_)
        }
        return @{
            MyKey = $this.MyKey
            Writeable = $value.MyWriteable
        }
    }

    [bool] Test () {
        $current = $this.Get()
        return $current.Writeable -eq $this.Writeable
    }

    [void] Set () {
        $this.ImportModule()

        try {
            Set-Something -Foo $this.MyKey -Bar $this.Writeable -ErrorAction Stop
        } catch {
            $this.WriteError("Something went wrong in Set - $_")
        }
    }
}

#endregion

#region inherit from other (simpler) resource

[DscResource()]
class RealResourceEx : realResource {
    [DscProperty(Mandatory)]
    [string]$SetScript
    
    [void] Set () {
        ([realResource]$this).Set()
        $script = [scriptblock]::Create($this.SetScript)
        $null = & $script
    }
}
#endregion

#region Using get() in test() and set()

[DscResource()]
class FewParameters {
    [DscProperty(Key)]
    [String]$Key
    
    [DscProperty()]
    [String]$First
    
    [DscProperty()]
    [String]$Second
    
    [FewParameters] Get () {
        return @{
            Key = $this.Key
            First = Get-First
            Second = Get-Second
        }
    }
    
    [bool] Test () {
        $current = $this.Get()
        return (
            $this.First -eq $current.First -and
            $this.Second -eq $current.Second
        )
    }
    
    [void] Set() {
        $current = $this.Get()
        
        if ($current.First -ne $this.First) {
            Set-First -Value $this.First
        }
        
        if ($current.Second -ne $this.Second) {
            Set-Second -Value $this.Second
        }
    }
}

#endregion

# Other
# -- MODULES!
# -- helper methods/ properties
# -- constants as properties not exposposed to outside world (without [DscResource])
# -- using try/catch/finally to make sure that cleanup *always* happens
# -- take advantage of constructors to initialize things before setting/ testing/ getting