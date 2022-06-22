using module MyResource\MyResource.psd1
$inMyModule = @{
    ModuleName = 'MyResource'
}
$myModule = Get-Module -Name MyResource
Describe "Testing classes in DSC module" {
    switch ($myModule.ExportedDscResources) {
        MyResource {
            Context $_ {
                BeforeAll {
                    InModuleScope MyResource {
                        Mock -CommandName Get-Date
                    }
                }
                BeforeEach {
                    $myResource = [MyResource]@{
                        MyKey = 'Test'
                    }
                }

                Context "Testing Get for resource $_" {
                    It "Key is a key..." {
                        $result = $myResource.Get()
                        $result.MyKey | Should -Be Test
                    }
                }

                Context "Testing Test for resource $_" {
                    It "Has to be bad..." {
                        $myResource.Test() | Should -BeFalse
                    }
                }

                Context "Testing Set for resource $_" {
                    # no method mocks, so...
                    BeforeEach {
                        $myResource | Add-Member -MemberType ScriptMethod -Name HelperMethod -Value {
                            Set-Content TestDrive:\foo.bar -Value 'Boom!'
                        } -Force
                    }

                    It "Uses Get-Date in Set" {
                        $myResource.Set()
                        Should -Invoke -CommandName Get-Date -Times 1 -Exactly -Scope It -ModuleName MyResource
                    }

                    It "Uses helper method in Set" {
                        'TestDrive:\foo.bar' | Should -Exist
                    }
                }
                }
        }
#
        PathElement {
            Context $_ {
                BeforeAll {
                    class FakeKey {
                        [String[]] GetValue (
                            [String]$Name,
                            [String]$DefaultValue,
                            [String]$Options
                        ) {
                            Set-Content -Path testdrive:\GetValue -Value ($PSBoundParameters | ConvertTo-Json)
                            return @(
                                'c:\foo\bar;c:\windows\temp'
                            )
                        }
                        [void] SetValue (
                            [String]$Name,
                            [String]$Value,
                            [String]$Type
                        ) {
                            Set-Content -Path testdrive:\SetValue -Value ($PSBoundParameters | ConvertTo-Json)
                        }
                    }
                    $continue = @{
                        ErrorAction = 'Continue'
                    }
                }
                BeforeEach {
                    $pathElement = [PathElement]@{
                        Path = 'c:\foo\bar'
                    }
                    $pathElement.RegistryHKLM | Add-Member -MemberType ScriptMethod -Name OpenSubKey -Value {
                        [FakeKey]::new()
                    } -Force
                }
                Context "Testing Get in $_" {
                    It "Gets correct state for existing path" {
                        $pathElement.Get().Ensure | Should -Be Present
                    }

                    It "Gets correct state for missing path" {
                        $pathElement.Path = 'c:\other\path'
                        $pathElement.Get().Ensure | Should -Be Absent
                    }
                    It "Should not depend on the previous tests" {
                        # $pathElement.Get().Ensure | Should -Be Absent
                    }
                    It "Should read the PATH variable with DoNotExpandEnvironmentNames option" {
                        $pathElement.Get()
                        $params = (GEt-Content -Raw -Path testdrive:\getValue | ConvertFrom-Json)
                        $params.Options | Should -BeExactly DoNotExpandEnvironmentNames -Because 'We may mess up registry if we forget it'
                    }
                }
                Context "Testing Test in $_" {
                    It "Should return <Result> when path <Path> is <Real> and should be <Expected>" {
                        $pathElement.Path = $Path
                        $pathElement.Ensure = $Expected
                        if ($Result) {
                            $splat = @{ BeTrue = $true }
                        } else {
                            $splat = @{ BeFalse = $true }
                        }
                        $pathElement.Test() | Should @splat
                    } -TestCases @(
                        @{
                            Path = 'c:\foo\bar'
                            Real = 'Present'
                            Expected = 'Present'
                            Result = $true
                        }
                        @{
                            Path = 'c:\foo\bar'
                            Real = 'Present'
                            Expected = 'Absent'
                            Result = $false
                        }
                        @{
                            Path = 'c:\foo\foo'
                            Real = 'Absent'
                            Expected = 'Present'
                            Result = $false
                        }
                        @{
                            Path = 'c:\foo\foo'
                            Real = 'Absent'
                            Expected = 'Absent'
                            Result = $true
                        }
                    )
            
                }

                Context "Testing Set in $_" {
                    It 'Should remove path when we ask for it' {
                        $pathElement.Ensure = 'Absent'
                        $pathElement.Set()
                        $params = (Get-Content -Path 'testdrive:\SetValue' | ConvertFrom-Json)
                        $params.Value | Should @continue -BeLike '*c:\windows\temp*' -Because 'other paths should not be touched'
                        $params.value | Should @continue -Not -BeLike '*foo\bar*'
                    }

                    It 'Should add path when we ask for it' {
                        $pathElement.Path = 'other\path'
                        $pathElement.Set()
                        $params = (Get-Content -Path 'testdrive:\SetValue' | ConvertFrom-Json)
                        $params.Value | Should @continue -BeLike '*c:\windows\temp*' -Because 'other paths should not be touched'
                        $params.value | Should @continue -BeLike '*other\path*'
                    }
                }
            }
        }
#>

        default {
            throw "Resource $_ has no tests!"
        }
    }
}