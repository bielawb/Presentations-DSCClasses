@{
    RootModule = 'MyResource.psm1'
    ModuleVersion = '1.0.0'
    GUID = '4fc53714-585a-43bc-9aad-84e38fb0a778'
    Author = 'Bartek'
    CompanyName = 'Unknown'
    Copyright = '(c) 2017 Bartek. All rights reserved.'
    DscResourcesToExport = @(
        'MyResource'
        'PathElement'
    )
    PrivateData = @{
        PSData = @{
            Tags = @(
                'DSC'
                'DscResource'
            )
        }
    }
}

