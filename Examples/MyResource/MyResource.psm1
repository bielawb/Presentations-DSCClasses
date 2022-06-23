[DSCResource()]
class MyResource {
    [DscProperty(Key)]
    [String]$MyKey

    [MyResource] Get () {
        return @{
            MyKey = $this.MyKey
        }
    }

    [bool] Test () {
        return $false
    }

    [void] Set () {
        Get-Date | Set-Content -Path C:\temp\Vienna.log -Force
        $this.HelperMethod()
    }

    [void] HelperMethod () {
        Restart-Service -Name Spooler
    }
}

<#
        Class that makes updating PATH variable straight-forward and easy to adjust rather than replace
#>

enum Ensure {
    Present
    Absent
}

class Base {
    [void] ReportIssue (
        [String]$Prefix,
        [System.Management.Automation.ErrorRecord]$ErrorRecord,
        [bool]$WriteError
    ) {
        $message = "$Prefix - $ErrorRecord ($($ErrorRecord.ScriptStackTrace)); Details:"
        $details = $ErrorRecord.CategoryInfo | Out-String -Stream | Where-Object {$_}
        if ($WriteError) {
            Write-Error -Message $message
            $details | Write-Error
        } else {
            Write-Verbose -Message $message
            $details | Write-Verbose
        }
    }

    [void] WriteError (
        [String]$Prefix,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    ) {
        $this.ReportIssue($Prefix, $ErrorRecord, $true)
    }

    [void] WriteVerbose (
        [String]$Prefix,
        [System.Management.Automation.ErrorRecord]$ErrorRecord
    ) {
        $this.ReportIssue($Prefix, $ErrorRecord, $false)
    }
}


[DscResource()]
class PathElement : Base {

    #region class properties

    # Path to folder that should be added to/ removed from PATH
    [DscProperty(Key)]
    [String] $Path
    
    # Flag to decide if path element should be added or removed
    [DscProperty()]
    [Ensure] $Ensure

    [String] $RegistryPath = 'SYSTEM\CurrentControlSet\Control\Session Manager\Environment'

    [Object] $RegistryHKLM = [Microsoft.Win32.Registry]::LocalMachine
    
    #endregion

    #region Standard methods

    [PathElement] Get () {
        $currentValue = try {
            $this.GetPathElements()
        } catch {
            $this.WriteVerbose('Failed to read PATH value', $_)
            ''
        }
        
        return @{
            Path = $this.Path
            Ensure = 
            if ($this.Path -in $currentValue) {
                [Ensure]::Present
            } else {
                [Ensure]::Absent
            }
        }
    }

    [bool] Test () {
        $currentValue = try {
            $this.GetPathElements()
        } catch {
            $this.WriteVerbose('Failed to read PATH value', $_)
            ''
        }

        Write-Verbose "Current PATH value: $currentValue"
        return (
            $this.Path -in $currentValue -xor
            $this.Ensure -eq [Ensure]::Absent
        )
    }

    [void] Set () {
        $currentValue = try {
            $this.GetPathElements()
        } catch {
            $this.WriteVerbose('Failed to read PATH value', $_)
            ''
        }

        $newValue = switch ($this.Ensure) {
            Present {
                Write-Verbose "Adding $($this.Path) to $currentValue"
                $currentValue + $this.Path    
            }
            Absent {
                Write-Verbose "Removing $($this.Path) from $currentValue"
                $currentValue | Where-Object { $_ -ne $this.Path }
            }
        }        
        try {
            $this.SetPathElements($newValue)
        } catch {
            $this.WriteError("Failed to update PATH with value '$newvalue'", $_)
        }
    }
    #endregion

    #region Helper methods
    [String[]] GetPathElements () {
        $registryValue = $this.RegistryHKLM.OpenSubKey($this.RegistryPath, $false).GetValue(
                'PATH',
                $null,
                'DoNotExpandEnvironmentNames'
            )
        return ($registryValue -split ';')
    }

    [void] SetPathElements ([string[]] $PathElements) {
        $fullPathValue = $PathElements -join ';'
        $this.RegistryHKLM.OpenSubKey($this.RegistryPath, $true).SetValue(
            'PATH',
            $fullPathValue,
            'ExpandString'
        )
    }
    #endregion
}