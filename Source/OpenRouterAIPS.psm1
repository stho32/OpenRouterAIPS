#Requires -Version 5.1

<#
.SYNOPSIS
    OpenRouterAIPS - PowerShell module for interacting with OpenRouter AI API

.DESCRIPTION
    This module provides PowerShell cmdlets for interacting with OpenRouter's AI API,
    enabling command-line access to various AI models through a unified interface.

.NOTES
    Author: OpenRouterAIPS
    Version: 1.0.0
    Requires: PowerShell 5.1+
    API Key: Set OPENROUTER_API_KEY environment variable
#>

# Module variables
$script:OpenRouterBaseUri = 'https://openrouter.ai/api/v1'
$script:DefaultModel = 'openai/gpt-3.5-turbo'
$script:DefaultMaxTokens = 1000
$script:DefaultTemperature = 0.7


# Private helper functions

function Get-OpenRouterApiKey {
    <#
    .SYNOPSIS
        Retrieves the OpenRouter API key from environment variable
    #>
    [CmdletBinding()]
    param()
    
    $apiKey = $env:OPENROUTER_API_KEY
    if (-not $apiKey) {
        throw 'OpenRouter API key not found. Please set the OPENROUTER_API_KEY environment variable.'
    }
    return $apiKey
}

function New-OpenRouterHeaders {
    <#
    .SYNOPSIS
        Creates HTTP headers for OpenRouter API requests
    #>
    [CmdletBinding()]
    param(
        [string]$ApiKey = (Get-OpenRouterApiKey),
        [string]$ContentType = 'application/json; charset=utf-8'
    )
    
    return @{
        'Authorization' = "Bearer $ApiKey"
        'Content-Type' = $ContentType
        'User-Agent' = 'OpenRouterAIPS/1.0.0 PowerShell'
    }
}


function Invoke-OpenRouterApiRequest {
    <#
    .SYNOPSIS
        Makes HTTP requests to OpenRouter API with error handling
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Endpoint,
        
        [ValidateSet('GET', 'POST')]
        [string]$Method = 'GET',
        
        [hashtable]$Body,
        
        [hashtable]$Headers = (New-OpenRouterHeaders)
    )
    
    try {
        $uri = "$script:OpenRouterBaseUri$Endpoint"
        Write-Verbose "Making $Method request to: $uri"
        
        $params = @{
            Uri = $uri
            Method = $Method
            Headers = $Headers
            ErrorAction = 'Stop'
        }
        
        if ($Body) {
            $jsonBody = ($Body | ConvertTo-Json -Depth 10)
            # Ensure proper UTF-8 encoding for the request body
            $params.Body = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
            Write-Verbose "Request body: $jsonBody"
        }
        
        $response = Invoke-WebRequest @params

        # Parse JSON response content with proper UTF-8 handling
        $responseContent = [System.Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())
        $jsonResponse = $responseContent | ConvertFrom-Json

        Write-Verbose "Parsed response with explicit UTF-8 encoding"

        return $jsonResponse
    }
    catch {
        $errorMessage = "OpenRouter API error: $($_.Exception.Message)"
        if ($_.Exception.Response) {
            $statusCode = $_.Exception.Response.StatusCode
            $errorMessage += " (HTTP $statusCode)"
        }
        Write-Error $errorMessage
        throw
    }
}

# Public functions

function Test-OpenRouterConnection {
    <#
    .SYNOPSIS
        Tests the connection to OpenRouter API
    
    .DESCRIPTION
        Verifies that the API key is set and can successfully connect to OpenRouter API
    
    .EXAMPLE
        Test-OpenRouterConnection
        
    .OUTPUTS
        Boolean indicating if connection is successful
    #>
    [CmdletBinding()]
    param()
    
    try {
        Write-Verbose 'Testing OpenRouter API connection...'
        $models = Invoke-OpenRouterApiRequest -Endpoint '/models'
        if ($models -and $models.data) {
            Write-Host 'Successfully connected to OpenRouter API' -ForegroundColor Green
            return $true
        }
        else {
            Write-Warning 'Connected to API but received unexpected response'
            return $false
        }
    }
    catch {
        Write-Error "Failed to connect to OpenRouter API: $($_.Exception.Message)"
        return $false
    }
}

function Get-OpenRouterModels {
    <#
    .SYNOPSIS
        Retrieves available AI models from OpenRouter
    
    .DESCRIPTION
        Gets a list of all available AI models with their details including pricing and context length
    
    .PARAMETER Filter
        Optional filter to search for specific models by name
    
    .EXAMPLE
        Get-OpenRouterModels
        
    .EXAMPLE
        Get-OpenRouterModels -Filter 'gpt'
        
    .OUTPUTS
        Array of model objects with properties like id, name, pricing, context_length
    #>
    [CmdletBinding()]
    param(
        [string]$Filter
    )
    
    try {
        Write-Verbose 'Retrieving available models from OpenRouter...'
        $response = Invoke-OpenRouterApiRequest -Endpoint '/models'
        
        $models = $response.data
        if ($Filter) {
            $models = $models | Where-Object { $_.id -like "*$Filter*" }
        }
        
        # Format output as custom objects
        $formattedModels = $models | ForEach-Object {
            [PSCustomObject]@{
                Id = $_.id
                Name = $_.id -replace '^[^/]+/', ''
                Provider = $_.id -replace '/.*$', ''
                ContextLength = $_.context_length
                PromptPrice = [decimal]($_.pricing.prompt -replace '[^0-9.]', '')
                CompletionPrice = [decimal]($_.pricing.completion -replace '[^0-9.]', '')
                Created = if ($_.created) { [datetime]::FromFileTimeUtc($_.created * 10000000 + 116444736000000000) } else { $null }
            }
        }
        
        return $formattedModels
    }
    catch {
        Write-Error "Failed to retrieve models: $($_.Exception.Message)"
        throw
    }
}


function Invoke-OpenRouterChat {
    <#
    .SYNOPSIS
        Sends a chat message to OpenRouter AI models
    
    .DESCRIPTION
        Interacts with AI models through OpenRouter API for chat completions
    
    .PARAMETER Message
        The message to send to the AI model
    
    .PARAMETER Model
        The AI model to use (default: openai/gpt-3.5-turbo) - supports auto-completion
    
    .PARAMETER MaxTokens
        Maximum number of tokens to generate (default: 1000)
    
    .PARAMETER Temperature
        Controls randomness in output (0.0 to 2.0, default: 0.7)
    
    .PARAMETER SystemPrompt
        Optional system prompt to set context for the conversation
    
    .PARAMETER Stream
        Enable streaming responses (not implemented in this version)
    
    .EXAMPLE
        Invoke-OpenRouterChat -Message 'Hello, how are you?'
        
    .EXAMPLE
        Invoke-OpenRouterChat -Message 'Explain quantum physics' -Model 'anthropic/claude-3-sonnet' -MaxTokens 2000
        
    .EXAMPLE
        'What is PowerShell?' | Invoke-OpenRouterChat
        
    .OUTPUTS
        Complete OpenRouter API response object with all fields preserved
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromPipeline)]
        [string]$Message,
        
        [Parameter()]
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            try {
                # Get available models from OpenRouter
                $models = Get-OpenRouterModels -ErrorAction SilentlyContinue
                
                if ($models) {
                    # Filter models based on what user has typed
                    $models | Where-Object { $_.Id -like "*$wordToComplete*" } | 
                        ForEach-Object { 
                            [System.Management.Automation.CompletionResult]::new(
                                $_.Id, 
                                $_.Id, 
                                'ParameterValue', 
                                "$($_.Provider)/$($_.Name) (Context: $($_.ContextLength))"
                            )
                        } | Select-Object -First 20  # Limit to 20 results
                }
            }
            catch {
                # Fallback to common models if API call fails
                $commonModels = @(
                    'openai/gpt-4o',
                    'openai/gpt-4-turbo', 
                    'openai/gpt-3.5-turbo',
                    'anthropic/claude-3-opus',
                    'anthropic/claude-3-sonnet', 
                    'anthropic/claude-3-haiku',
                    'google/gemini-pro',
                    'meta-llama/llama-2-70b-chat'
                )
                
                $commonModels | Where-Object { $_ -like "*$wordToComplete*" } | 
                    ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                    }
            }
        })]
        [string]$Model = $script:DefaultModel,
        
        [ValidateRange(1, 32000)]
        [int]$MaxTokens = $script:DefaultMaxTokens,
        
        [ValidateRange(0.0, 2.0)]
        [decimal]$Temperature = $script:DefaultTemperature,
        
        [string]$SystemPrompt,
        
        [switch]$Stream
    )
    
    process {
        try {
            Write-Verbose "Sending message to model: $Model"
            
            # Build messages array
            $messages = @()
            if ($SystemPrompt) {
                $messages += @{
                    role = 'system'
                    content = $SystemPrompt
                }
            }
            $messages += @{
                role = 'user'
                content = $Message
            }
            
            # Build request body
            $requestBody = @{
                model = $Model
                messages = $messages
                max_tokens = $MaxTokens
                temperature = [double]$Temperature
            }
            
            if ($Stream) {
                Write-Warning 'Streaming is not implemented in this version'
            }
            
            # Make API request
            $response = Invoke-OpenRouterApiRequest -Endpoint '/chat/completions' -Method 'POST' -Body $requestBody
            
            Write-Verbose "Received response from OpenRouter API"
            Write-Verbose "Response ID: $($response.id)"
            Write-Verbose "Model: $($response.model)"
            Write-Verbose "Choices count: $($response.choices.Count)"
            
            
            # Return the complete OpenRouter response as-is
            return $response
        }
        catch {
            Write-Error "Failed to get chat completion: $($_.Exception.Message)"
            throw
        }
    }
}

function Get-OpenRouterConfig {
    <#
    .SYNOPSIS
        Gets current OpenRouter configuration
    
    .DESCRIPTION
        Displays current module configuration including default model and settings
    
    .EXAMPLE
        Get-OpenRouterConfig
        
    .OUTPUTS
        PSCustomObject with current configuration settings
    #>
    [CmdletBinding()]
    param()
    
    $hasApiKey = -not [string]::IsNullOrEmpty($env:OPENROUTER_API_KEY)
    
    return [PSCustomObject]@{
        ApiKeySet = $hasApiKey
        BaseUri = $script:OpenRouterBaseUri
        DefaultModel = $script:DefaultModel
        DefaultMaxTokens = $script:DefaultMaxTokens
        DefaultTemperature = $script:DefaultTemperature
        ModuleVersion = '1.0.0'
    }
}

function Set-OpenRouterConfig {
    <#
    .SYNOPSIS
        Sets OpenRouter configuration options
    
    .DESCRIPTION
        Configures default settings for the OpenRouter module
    
    .PARAMETER DefaultModel
        Set the default AI model to use - supports auto-completion
    
    .PARAMETER DefaultMaxTokens
        Set the default maximum tokens for responses
    
    .PARAMETER DefaultTemperature
        Set the default temperature for responses
    
    .EXAMPLE
        Set-OpenRouterConfig -DefaultModel 'anthropic/claude-3-sonnet'
        
    .EXAMPLE
        Set-OpenRouterConfig -DefaultMaxTokens 2000 -DefaultTemperature 0.5
    #>
    [CmdletBinding()]
    param(
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            try {
                # Get available models from OpenRouter
                $models = Get-OpenRouterModels -ErrorAction SilentlyContinue
                
                if ($models) {
                    # Filter models based on what user has typed
                    $models | Where-Object { $_.Id -like "*$wordToComplete*" } | 
                        ForEach-Object { 
                            [System.Management.Automation.CompletionResult]::new(
                                $_.Id, 
                                $_.Id, 
                                'ParameterValue', 
                                "$($_.Provider)/$($_.Name) (Context: $($_.ContextLength))"
                            )
                        } | Select-Object -First 20  # Limit to 20 results
                }
            }
            catch {
                # Fallback to common models if API call fails
                $commonModels = @(
                    'openai/gpt-4o',
                    'openai/gpt-4-turbo', 
                    'openai/gpt-3.5-turbo',
                    'anthropic/claude-3-opus',
                    'anthropic/claude-3-sonnet', 
                    'anthropic/claude-3-haiku',
                    'google/gemini-pro',
                    'meta-llama/llama-2-70b-chat'
                )
                
                $commonModels | Where-Object { $_ -like "*$wordToComplete*" } | 
                    ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                    }
            }
        })]
        [string]$DefaultModel,
        
        [ValidateRange(1, 32000)]
        [int]$DefaultMaxTokens,
        
        [ValidateRange(0.0, 2.0)]
        [decimal]$DefaultTemperature
    )
    
    if ($DefaultModel) {
        $script:DefaultModel = $DefaultModel
        Write-Host "Default model set to: $DefaultModel" -ForegroundColor Green
    }
    
    if ($DefaultMaxTokens) {
        $script:DefaultMaxTokens = $DefaultMaxTokens
        Write-Host "Default max tokens set to: $DefaultMaxTokens" -ForegroundColor Green
    }
    
    if ($DefaultTemperature) {
        $script:DefaultTemperature = $DefaultTemperature
        Write-Host "Default temperature set to: $DefaultTemperature" -ForegroundColor Green
    }
}

# Create aliases
New-Alias -Name 'orchat' -Value 'Invoke-OpenRouterChat' -Description 'Short alias for Invoke-OpenRouterChat'
New-Alias -Name 'ormodels' -Value 'Get-OpenRouterModels' -Description 'Short alias for Get-OpenRouterModels'

# Export functions and aliases
Export-ModuleMember -Function @(
    'Invoke-OpenRouterChat',
    'Get-OpenRouterModels', 
    'Get-OpenRouterConfig',
    'Set-OpenRouterConfig',
    'Test-OpenRouterConnection'
) -Alias @('orchat', 'ormodels')

Write-Verbose 'OpenRouterAIPS module loaded successfully'
