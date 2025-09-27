@{
    # Script module or binary module file associated with this manifest.
    RootModule = 'OpenRouterAIPS.psm1'

    # Version number of this module.
    ModuleVersion = '1.0.0'

    # Supported PSEditions
    CompatiblePSEditions = @('Desktop', 'Core')

    # ID used to uniquely identify this module
    GUID = 'a1b2c3d4-e5f6-7890-abcd-ef1234567890'

    # Author of this module
    Author = 'OpenRouterAIPS'

    # Company or vendor of this module
    CompanyName = 'OpenRouterAIPS'

    # Copyright statement for this module
    Copyright = '(c) 2025 OpenRouterAIPS. All rights reserved.'

    # Description of the functionality provided by this module
    Description = 'PowerShell module for interacting with OpenRouter AI API to provide command-line tools for AI model access'

    # Minimum version of the PowerShell engine required by this module
    PowerShellVersion = '5.1'

    # Functions to export from this module
    FunctionsToExport = @(
        'Invoke-OpenRouterChat',
        'Get-OpenRouterModels',
        'Get-OpenRouterConfig',
        'Set-OpenRouterConfig',
        'Test-OpenRouterConnection',
        'Start-OpenRouterChat',
        'Get-OpenRouterChatHistory',
        'Save-OpenRouterChatHistory',
        'Clear-OpenRouterChatHistory',
        'Set-OpenRouterChatConfig',
        'Get-OpenRouterChatConfig'
    )

    # Cmdlets to export from this module
    CmdletsToExport = @()

    # Variables to export from this module
    VariablesToExport = @()

    # Aliases to export from this module
    AliasesToExport = @(
        'orchat',
        'ormodels',
        'orchat-session',
        'orchat-history',
        'orchat-save',
        'orchat-clear',
        'orchat-config'
    )

    # Private data to pass to the module specified in RootModule/ModuleToProcess
    PrivateData = @{
        PSData = @{
            # Tags applied to this module
            Tags = @('OpenRouter', 'AI', 'API', 'ChatGPT', 'Claude', 'PowerShell')

            # A URL to the license for this module.
            LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://github.com/openrouter-aips'

            # A URL to an icon representing this module.
            IconUri = ''

            # ReleaseNotes of this module
            ReleaseNotes = 'Initial release of OpenRouterAIPS PowerShell module'
        }
    }
}