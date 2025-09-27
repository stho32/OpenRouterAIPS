#Requires -Version 5.1

<#
.SYNOPSIS
    OpenRouterAIPS.Chat - Interactive chat terminal functionality for OpenRouterAIPS module

.DESCRIPTION
    This module provides interactive chat terminal functionality for OpenRouterAIPS,
    enabling streaming conversations, chat history management, and session commands.

.NOTES
    Author: OpenRouterAIPS
    Version: 1.0.0
    Requires: PowerShell 5.1+, OpenRouterAIPS module
    API Key: Set OPENROUTER_API_KEY environment variable
#>

# Import required functions from main module if not already available
# Note: This module should only be imported after the main OpenRouterAIPS module is loaded

# Internal function for API calls with full conversation history
function Invoke-ChatAPIRequest {
    <#
    .SYNOPSIS
        Internal function for making API calls with full conversation history
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [array]$Messages,
        
        [Parameter(Mandatory)]
        [string]$Model,
        
        [ValidateRange(1, 32000)]
        [int]$MaxTokens = 1000,
        
        [ValidateRange(0.0, 2.0)]
        [decimal]$Temperature = 0.7
    )
    
    try {
        # Get API key
        $apiKey = $env:OPENROUTER_API_KEY
        if (-not $apiKey) {
            throw 'OpenRouter API key not found. Please set the OPENROUTER_API_KEY environment variable.'
        }
        
        # Build headers
        $headers = @{
            'Authorization' = "Bearer $apiKey"
            'Content-Type'  = 'application/json; charset=utf-8'
            'User-Agent'    = 'OpenRouterAIPS/1.0.0 PowerShell'
        }
        
        # Build request body
        $requestBody = @{
            model       = $Model
            messages    = $Messages
            max_tokens  = $MaxTokens
            temperature = [double]$Temperature
        }
        
        $uri = 'https://openrouter.ai/api/v1/chat/completions'
        $jsonBody = ($requestBody | ConvertTo-Json -Depth 10)
        
        Write-Verbose "Making chat API request to: $uri"
        Write-Verbose "Request body: $jsonBody"
        
        # Make the API request
        $params = @{
            Uri         = $uri
            Method      = 'POST'
            Headers     = $headers
            Body        = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
            ErrorAction = 'Stop'
        }
        
        $response = Invoke-WebRequest @params
        $responseContent = [System.Text.Encoding]::UTF8.GetString($response.RawContentStream.ToArray())
        $jsonResponse = $responseContent | ConvertFrom-Json
        
        Write-Verbose "Received response from OpenRouter API"
        return $jsonResponse
    }
    catch {
        Write-Error "Failed to make chat API request: $($_.Exception.Message)"
        throw
    }
}

# Module variables for chat sessions
$script:ChatHistory = @()
$script:ChatSession = @{
    Active           = $false
    Model            = $null
    MaxTokens        = 1000
    Temperature      = 0.7
    SystemPrompt     = $null
    TotalTokens      = 0
    TotalCost        = 0.0
    MessageCount     = 0
    SessionStartTime = $null
    LastActivity     = $null
}

# Chat configuration
$script:ChatConfig = @{
    UserColor              = 'Cyan'
    AIColor                = 'Green'
    SystemColor            = 'Yellow'
    ErrorColor             = 'Red'
    InfoColor              = 'Gray'
    PromptColor            = 'White'
    StreamingEnabled       = $true
    MaxHistoryLength       = 100
    AutoSave               = $false
    ShowTimestamps         = $false
    ShowTokenUsage         = $true
    ShowCost               = $true
    BudgetLimit            = 0.0
    BudgetWarningThreshold = 0.8
}

# Private helper functions

function Write-ChatMessage {
    <#
    .SYNOPSIS
        Writes a formatted chat message to the console
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,
        
        [Parameter(Mandatory)]
        [ValidateSet('User', 'AI', 'System', 'Error', 'Info')]
        [string]$Type,
        
        [switch]$NoNewline,
        
        [switch]$ShowTimestamp
    )
    
    $color = switch ($Type) {
        'User' { $script:ChatConfig.UserColor }
        'AI' { $script:ChatConfig.AIColor }
        'System' { $script:ChatConfig.SystemColor }
        'Error' { $script:ChatConfig.ErrorColor }
        'Info' { $script:ChatConfig.InfoColor }
    }
    
    $prefix = switch ($Type) {
        'User' { 'You: ' }
        'AI' { 'AI: ' }
        'System' { '[System]: ' }
        'Error' { '[Error]: ' }
        'Info' { '[Info]: ' }
    }
    
    if ($ShowTimestamp -or $script:ChatConfig.ShowTimestamps) {
        $timestamp = Get-Date -Format 'HH:mm:ss'
        $prefix = "[$timestamp] $prefix"
    }
    
    if ($NoNewline) {
        Write-Host "$prefix$Message" -ForegroundColor $color -NoNewline
    }
    else {
        Write-Host "$prefix$Message" -ForegroundColor $color
    }
}

function Add-ChatHistoryEntry {
    <#
    .SYNOPSIS
        Adds an entry to the chat history
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateSet('user', 'assistant', 'system')]
        [string]$Role,
        
        [Parameter(Mandatory)]
        [string]$Content,
        
        [hashtable]$Metadata = @{}
    )
    
    $entry = @{
        Role      = $Role
        Content   = $Content
        Timestamp = Get-Date
        Metadata  = $Metadata
    }
    
    $script:ChatHistory += $entry
    
    # Trim history if it exceeds maximum length
    if ($script:ChatHistory.Count -gt $script:ChatConfig.MaxHistoryLength) {
        $script:ChatHistory = $script:ChatHistory[ - $script:ChatConfig.MaxHistoryLength..-1]
    }
}

function Get-StreamingResponse {
    <#
    .SYNOPSIS
        Handles streaming response from OpenRouter API
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$RequestBody
    )
    
    try {
        # Enable streaming in request body
        $RequestBody.stream = $true
        
        # Get API key and build headers
        $apiKey = $env:OPENROUTER_API_KEY
        if (-not $apiKey) {
            throw 'OpenRouter API key not found. Please set the OPENROUTER_API_KEY environment variable.'
        }
        
        $headers = @{
            'Authorization' = "Bearer $apiKey"
            'Content-Type'  = 'application/json; charset=utf-8'
            'User-Agent'    = 'OpenRouterAIPS/1.0.0 PowerShell'
        }
        
        $uri = 'https://openrouter.ai/api/v1/chat/completions'
        $jsonBody = ($RequestBody | ConvertTo-Json -Depth 10)
        
        Write-ChatMessage "Thinking..." -Type Info
        
        # Create a new HTTP request for streaming
        $httpRequest = [System.Net.HttpWebRequest]::Create($uri)
        $httpRequest.Method = 'POST'
        $httpRequest.ContentType = 'application/json; charset=utf-8'
        $httpRequest.UserAgent = 'OpenRouterAIPS/1.0.0 PowerShell'
        $httpRequest.Headers.Add('Authorization', "Bearer $apiKey")
        
        # Write request body
        $requestStream = $httpRequest.GetRequestStream()
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($jsonBody)
        $requestStream.Write($bytes, 0, $bytes.Length)
        $requestStream.Close()
        
        # Get response stream
        $response = $httpRequest.GetResponse()
        $responseStream = $response.GetResponseStream()
        $reader = New-Object System.IO.StreamReader($responseStream)
        
        $completeResponse = ''
        $totalTokens = 0
        
        Write-Host "`n" -NoNewline
        # Write AI prefix without using Write-ChatMessage to avoid empty string error
        Write-Host "AI: " -NoNewline -ForegroundColor $script:ChatConfig.AIColor
        
        # Read streaming data
        while (-not $reader.EndOfStream) {
            $line = $reader.ReadLine()
            
            if ($line.StartsWith('data: ') -and $line -ne 'data: [DONE]') {
                try {
                    $jsonData = $line.Substring(6)
                    $chunk = $jsonData | ConvertFrom-Json
                    
                    if ($chunk.choices -and $chunk.choices[0].delta.content) {
                        $content = $chunk.choices[0].delta.content
                        Write-Host $content -NoNewline -ForegroundColor $script:ChatConfig.AIColor
                        $completeResponse += $content
                    }
                    
                    # Extract usage information if available
                    if ($chunk.usage) {
                        $totalTokens = $chunk.usage.total_tokens
                    }
                }
                catch {
                    # Skip malformed JSON chunks
                    continue
                }
            }
        }
        
        Write-Host "`n"
        
        # Clean up
        $reader.Close()
        $responseStream.Close()
        $response.Close()
        
        return @{
            Content     = $completeResponse
            TotalTokens = $totalTokens
            Model       = $RequestBody.model
        }
    }
    catch {
        Write-ChatMessage "Streaming error: $($_.Exception.Message)" -Type Error
        # Fallback to non-streaming request using the complete request body
        $RequestBody.Remove('stream')
        
        # Use direct API call instead of Invoke-OpenRouterChat to maintain context
        try {
            # Build the complete message array for the API call
            $apiMessages = @()
            foreach ($entry in $script:ChatHistory) {
                $apiMessages += @{
                    role    = $entry.Role
                    content = $entry.Content
                }
            }
            
            # Make the API call using the internal function with complete context
            $response = Invoke-ChatAPIRequest -Messages $apiMessages -Model $script:ChatSession.Model -MaxTokens $script:ChatSession.MaxTokens -Temperature $script:ChatSession.Temperature
            
            if ($response -and $response.choices -and $response.choices[0].message) {
                return @{
                    Content     = $response.choices[0].message.content
                    TotalTokens = if ($response.usage) { $response.usage.total_tokens } else { 0 }
                    Model       = $response.model
                }
            }
        }
        catch {
            Write-Verbose "API fallback call also failed: $($_.Exception.Message)"
        }
        
        throw "Failed to get response: $($_.Exception.Message)"
    }
}

function Show-ChatHelp {
    <#
    .SYNOPSIS
        Displays help for chat commands
    #>
    Write-ChatMessage "Available commands:" -Type System
    Write-Host "  /exit, /quit        - End the chat session" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /clear              - Clear conversation history" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /help               - Show this help message" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /model <name>       - Switch AI model" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /models             - List available models" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /save <filename>    - Save conversation to file" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /load <filename>    - Load conversation from file" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /tokens             - Show token usage statistics" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /cost               - Show session cost statistics" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /stats              - Show generation statistics" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /config             - Display current configuration" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /stream on|off      - Toggle streaming responses" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  /system <prompt>    - Set system prompt" -ForegroundColor $script:ChatConfig.InfoColor
}

function Show-SessionStats {
    <#
    .SYNOPSIS
        Displays session statistics
    #>
    Write-ChatMessage "Session Statistics:" -Type System
    Write-Host "  Model: $($script:ChatSession.Model)" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  Messages: $($script:ChatSession.MessageCount)" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  Total Tokens: $($script:ChatSession.TotalTokens)" -ForegroundColor $script:ChatConfig.InfoColor
    Write-Host "  Total Cost: `$$([math]::Round($script:ChatSession.TotalCost, 4))" -ForegroundColor $script:ChatConfig.InfoColor
    
    if ($script:ChatSession.SessionStartTime) {
        $duration = (Get-Date) - $script:ChatSession.SessionStartTime
        Write-Host "  Session Duration: $($duration.ToString('hh\:mm\:ss'))" -ForegroundColor $script:ChatConfig.InfoColor
    }
}

function Get-ModelPricing {
    <#
    .SYNOPSIS
        Gets pricing information for a model
    #>
    [CmdletBinding()]
    param(
        [string]$ModelId
    )
    
    try {
        $models = Get-OpenRouterModels
        $model = $models | Where-Object { $_.Id -eq $ModelId }
        
        if ($model) {
            return @{
                PromptPrice     = $model.PromptPrice
                CompletionPrice = $model.CompletionPrice
            }
        }
    }
    catch {
        # Return default pricing if unable to get from API
    }
    
    return @{
        PromptPrice     = 0.0
        CompletionPrice = 0.0
    }
}

function Update-SessionCost {
    <#
    .SYNOPSIS
        Updates session cost based on token usage
    #>
    [CmdletBinding()]
    param(
        [int]$PromptTokens = 0,
        [int]$CompletionTokens = 0,
        [string]$Model
    )
    
    if (-not $script:ChatConfig.ShowCost) {
        return
    }
    
    $pricing = Get-ModelPricing -ModelId $Model
    
    # Calculate cost (pricing is typically per 1K tokens)
    $promptCost = ($PromptTokens / 1000) * $pricing.PromptPrice
    $completionCost = ($CompletionTokens / 1000) * $pricing.CompletionPrice
    $totalCost = $promptCost + $completionCost
    
    $script:ChatSession.TotalCost += $totalCost
    
    # Check budget warnings
    if ($script:ChatConfig.BudgetLimit -gt 0 -and $script:ChatSession.TotalCost -gt ($script:ChatConfig.BudgetLimit * $script:ChatConfig.BudgetWarningThreshold)) {
        $remainingBudget = $script:ChatConfig.BudgetLimit - $script:ChatSession.TotalCost
        if ($remainingBudget -le 0) {
            Write-ChatMessage "Budget limit exceeded! Current cost: `$$([math]::Round($script:ChatSession.TotalCost, 4))" -Type Error
        }
        else {
            Write-ChatMessage "Budget warning: `$$([math]::Round($remainingBudget, 4)) remaining" -Type System
        }
    }
}

# Public functions

function Start-OpenRouterChat {
    <#
    .SYNOPSIS
        Starts an interactive chat session with OpenRouter AI models
    
    .DESCRIPTION
        Launches an interactive chat terminal that supports streaming responses,
        conversation history, model switching, and various session commands.
    
    .PARAMETER Model
        The AI model to use for the chat session (supports auto-completion)
    
    .PARAMETER SystemPrompt
        Optional system prompt to set context for the conversation
    
    .PARAMETER MaxTokens
        Maximum number of tokens to generate per response (default: 1000)
    
    .PARAMETER Temperature
        Controls randomness in output (0.0 to 2.0, default: 0.7)
    
    .PARAMETER NoStreaming
        Disable streaming responses and use traditional request/response
    
    .EXAMPLE
        Start-OpenRouterChat
        
    .EXAMPLE
        Start-OpenRouterChat -Model 'anthropic/claude-3-sonnet' -SystemPrompt 'You are a helpful coding assistant'
        
    .EXAMPLE
        orchat-session -Model 'openai/gpt-4' -NoStreaming
    #>
    [CmdletBinding()]
    param(
        [ArgumentCompleter({
                param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
                try {
                    $models = Get-OpenRouterModels -ErrorAction SilentlyContinue
                
                    if ($models) {
                        $models | Where-Object { $_.Id -like "*$wordToComplete*" } | 
                        ForEach-Object { 
                            [System.Management.Automation.CompletionResult]::new(
                                $_.Id, 
                                $_.Id, 
                                'ParameterValue', 
                                "$($_.Provider)/$($_.Name) (Context: $($_.ContextLength))"
                            )
                        } | Select-Object -First 20
                    }
                }
                catch {
                    $commonModels = @(
                        'openai/gpt-4o',
                        'openai/gpt-4-turbo', 
                        'openai/gpt-3.5-turbo',
                        'anthropic/claude-3-opus',
                        'anthropic/claude-3-sonnet', 
                        'anthropic/claude-3-haiku'
                    )
                
                    $commonModels | Where-Object { $_ -like "*$wordToComplete*" } | 
                    ForEach-Object {
                        [System.Management.Automation.CompletionResult]::new($_, $_, 'ParameterValue', $_)
                    }
                }
            })]
        [string]$Model,
        
        [string]$SystemPrompt,
        
        [ValidateRange(1, 32000)]
        [int]$MaxTokens = 1000,
        
        [ValidateRange(0.0, 2.0)]
        [decimal]$Temperature = 0.7,
        
        [switch]$NoStreaming
    )
    
    # Test connection first
    if (-not (Test-OpenRouterConnection)) {
        Write-ChatMessage "Failed to connect to OpenRouter API. Please check your API key and internet connection." -Type Error
        return
    }
    
    # Initialize session
    $script:ChatSession.Active = $true
    $script:ChatSession.Model = if ($Model) { $Model } else { (Get-OpenRouterConfig).DefaultModel }
    $script:ChatSession.MaxTokens = $MaxTokens
    $script:ChatSession.Temperature = $Temperature
    $script:ChatSession.SystemPrompt = $SystemPrompt
    $script:ChatSession.SessionStartTime = Get-Date
    $script:ChatSession.MessageCount = 0
    $script:ChatSession.TotalTokens = 0
    $script:ChatSession.TotalCost = 0.0
    
    if ($NoStreaming) {
        $script:ChatConfig.StreamingEnabled = $false
    }
    
    # Clear history and add system prompt if provided
    $script:ChatHistory = @()
    if ($SystemPrompt) {
        Add-ChatHistoryEntry -Role 'system' -Content $SystemPrompt
    }
    
    # Display welcome message
    Write-Host "`n" + "="*60 -ForegroundColor $script:ChatConfig.SystemColor
    Write-ChatMessage "OpenRouter AI Chat Session Started" -Type System
    Write-ChatMessage "Model: $($script:ChatSession.Model)" -Type Info
    if ($SystemPrompt) {
        Write-ChatMessage "System Prompt: $SystemPrompt" -Type Info
    }
    Write-ChatMessage "Type '/help' for commands or '/exit' to quit" -Type Info
    Write-Host "="*60 + "`n" -ForegroundColor $script:ChatConfig.SystemColor
    
    # Main chat loop
    while ($script:ChatSession.Active) {
        try {
            # Get user input
            Write-Host "You: " -ForegroundColor $script:ChatConfig.PromptColor -NoNewline
            $userInput = Read-Host
            
            # Skip empty input
            if ([string]::IsNullOrWhiteSpace($userInput)) {
                continue
            }
            
            # Handle commands
            if ($userInput.StartsWith('/')) {
                $parts = $userInput.Split(' ', 2)
                $command = $parts[0].ToLower()
                $argument = if ($parts.Length -gt 1) { $parts[1] } else { '' }
                
                switch ($command) {
                    '/exit' { 
                        $script:ChatSession.Active = $false
                        Write-ChatMessage "Chat session ended. Goodbye!" -Type System
                        break
                    }
                    '/quit' { 
                        $script:ChatSession.Active = $false
                        Write-ChatMessage "Chat session ended. Goodbye!" -Type System
                        break
                    }
                    '/clear' {
                        $script:ChatHistory = @()
                        if ($script:ChatSession.SystemPrompt) {
                            Add-ChatHistoryEntry -Role 'system' -Content $script:ChatSession.SystemPrompt
                        }
                        $script:ChatSession.MessageCount = 0
                        Write-ChatMessage "Conversation history cleared." -Type System
                        break
                    }
                    '/help' {
                        Show-ChatHelp
                        break
                    }
                    '/model' {
                        if ($argument) {
                            try {
                                # Validate model exists
                                $models = Get-OpenRouterModels
                                $selectedModel = $models | Where-Object { $_.Id -eq $argument }
                                
                                if ($selectedModel) {
                                    $script:ChatSession.Model = $argument
                                    Write-ChatMessage "Switched to model: $argument" -Type System
                                }
                                else {
                                    Write-ChatMessage "Model '$argument' not found. Use '/models' to see available models." -Type Error
                                }
                            }
                            catch {
                                Write-ChatMessage "Error switching model: $($_.Exception.Message)" -Type Error
                            }
                        }
                        else {
                            Write-ChatMessage "Current model: $($script:ChatSession.Model)" -Type Info
                            Write-ChatMessage "Usage: /model <model-name>" -Type Info
                        }
                        break
                    }
                    '/models' {
                        try {
                            Write-ChatMessage "Available models:" -Type System
                            $models = Get-OpenRouterModels | Select-Object -First 20
                            $models | ForEach-Object {
                                $contextInfo = if ($_.ContextLength) { " (Context: $($_.ContextLength))" } else { "" }
                                Write-Host "  $($_.Id)$contextInfo" -ForegroundColor $script:ChatConfig.InfoColor
                            }
                            Write-ChatMessage "Use '/model <model-id>' to switch models" -Type Info
                        }
                        catch {
                            Write-ChatMessage "Error retrieving models: $($_.Exception.Message)" -Type Error
                        }
                        break
                    }
                    '/save' {
                        if ($argument) {
                            try {
                                Save-OpenRouterChatHistory -FilePath $argument
                                Write-ChatMessage "Conversation saved to: $argument" -Type System
                            }
                            catch {
                                Write-ChatMessage "Error saving conversation: $($_.Exception.Message)" -Type Error
                            }
                        }
                        else {
                            Write-ChatMessage "Usage: /save <filename>" -Type Info
                        }
                        break
                    }
                    '/load' {
                        if ($argument) {
                            try {
                                $loadedHistory = Get-Content -Path $argument -Raw | ConvertFrom-Json
                                $script:ChatHistory = @()
                                foreach ($entry in $loadedHistory) {
                                    Add-ChatHistoryEntry -Role $entry.Role -Content $entry.Content
                                }
                                Write-ChatMessage "Conversation loaded from: $argument" -Type System
                                Write-ChatMessage "Loaded $($loadedHistory.Count) messages" -Type Info
                            }
                            catch {
                                Write-ChatMessage "Error loading conversation: $($_.Exception.Message)" -Type Error
                            }
                        }
                        else {
                            Write-ChatMessage "Usage: /load <filename>" -Type Info
                        }
                        break
                    }
                    '/tokens' {
                        Write-ChatMessage "Token Usage:" -Type System
                        Write-Host "  Session Total: $($script:ChatSession.TotalTokens)" -ForegroundColor $script:ChatConfig.InfoColor
                        Write-Host "  Messages: $($script:ChatSession.MessageCount)" -ForegroundColor $script:ChatConfig.InfoColor
                        break
                    }
                    '/cost' {
                        Write-ChatMessage "Cost Information:" -Type System
                        Write-Host "  Session Cost: `$$([math]::Round($script:ChatSession.TotalCost, 4))" -ForegroundColor $script:ChatConfig.InfoColor
                        if ($script:ChatConfig.BudgetLimit -gt 0) {
                            $remaining = $script:ChatConfig.BudgetLimit - $script:ChatSession.TotalCost
                            Write-Host "  Budget Remaining: `$$([math]::Round($remaining, 4))" -ForegroundColor $script:ChatConfig.InfoColor
                        }
                        break
                    }
                    '/stats' {
                        Show-SessionStats
                        break
                    }
                    '/config' {
                        Write-ChatMessage "Current Configuration:" -Type System
                        Write-Host "  Model: $($script:ChatSession.Model)" -ForegroundColor $script:ChatConfig.InfoColor
                        Write-Host "  Max Tokens: $($script:ChatSession.MaxTokens)" -ForegroundColor $script:ChatConfig.InfoColor
                        Write-Host "  Temperature: $($script:ChatSession.Temperature)" -ForegroundColor $script:ChatConfig.InfoColor
                        Write-Host "  Streaming: $($script:ChatConfig.StreamingEnabled)" -ForegroundColor $script:ChatConfig.InfoColor
                        Write-Host "  Show Timestamps: $($script:ChatConfig.ShowTimestamps)" -ForegroundColor $script:ChatConfig.InfoColor
                        break
                    }
                    '/stream' {
                        if ($argument -eq 'on') {
                            $script:ChatConfig.StreamingEnabled = $true
                            Write-ChatMessage "Streaming enabled" -Type System
                        }
                        elseif ($argument -eq 'off') {
                            $script:ChatConfig.StreamingEnabled = $false
                            Write-ChatMessage "Streaming disabled" -Type System
                        }
                        else {
                            Write-ChatMessage "Streaming is currently: $(if ($script:ChatConfig.StreamingEnabled) { 'enabled' } else { 'disabled' })" -Type Info
                            Write-ChatMessage "Usage: /stream on|off" -Type Info
                        }
                        break
                    }
                    '/system' {
                        if ($argument) {
                            $script:ChatSession.SystemPrompt = $argument
                            # Update history with new system prompt
                            $script:ChatHistory = $script:ChatHistory | Where-Object { $_.Role -ne 'system' }
                            Add-ChatHistoryEntry -Role 'system' -Content $argument
                            Write-ChatMessage "System prompt updated: $argument" -Type System
                        }
                        else {
                            if ($script:ChatSession.SystemPrompt) {
                                Write-ChatMessage "Current system prompt: $($script:ChatSession.SystemPrompt)" -Type Info
                            }
                            else {
                                Write-ChatMessage "No system prompt set" -Type Info
                            }
                            Write-ChatMessage "Usage: /system <prompt>" -Type Info
                        }
                        break
                    }
                    default {
                        Write-ChatMessage "Unknown command: $command. Type '/help' for available commands." -Type Error
                        break
                    }
                }
                continue
            }
            
            # Add user message to history
            Add-ChatHistoryEntry -Role 'user' -Content $userInput
            $script:ChatSession.MessageCount++
            $script:ChatSession.LastActivity = Get-Date
            
            # Store the user input for reliable access
            $currentUserMessage = $userInput
            Write-Verbose "DEBUG: currentUserMessage = '$currentUserMessage'"
            Write-Verbose "DEBUG: userInput = '$userInput'"
            
            # Prepare messages for API call
            $messages = @()
            foreach ($entry in $script:ChatHistory) {
                $messages += @{
                    role    = $entry.Role
                    content = $entry.Content
                }
            }
            
            # Build request body
            $requestBody = @{
                model       = $script:ChatSession.Model
                messages    = $messages
                max_tokens  = $script:ChatSession.MaxTokens
                temperature = [double]$script:ChatSession.Temperature
            }
            
            # Get AI response
            if ($script:ChatConfig.StreamingEnabled) {
                try {
                    $response = Get-StreamingResponse -RequestBody $requestBody
                    $aiResponse = $response.Content
                    $tokensUsed = $response.TotalTokens
                }
                catch {
                    Write-ChatMessage "Streaming error: $($_.Exception.Message)" -Type Error
                    Write-Verbose "DEBUG: In catch block - currentUserMessage = '$currentUserMessage'"
                    
                    # Fallback to regular API call using stored message
                    if (-not [string]::IsNullOrWhiteSpace($currentUserMessage)) {
                        Write-Verbose "DEBUG: About to call chat with full history"
                        
                        # Build the complete message array for the API call
                        $apiMessages = @()
                        foreach ($entry in $script:ChatHistory) {
                            $apiMessages += @{
                                role    = $entry.Role
                                content = $entry.Content
                            }
                        }
                        
                        # Use the internal function to maintain conversation context
                        $apiResponse = Invoke-ChatAPIRequest -Messages $apiMessages -Model $script:ChatSession.Model -MaxTokens $script:ChatSession.MaxTokens -Temperature $script:ChatSession.Temperature
                        $aiResponse = $apiResponse.choices[0].message.content
                        $tokensUsed = if ($apiResponse.usage) { $apiResponse.usage.total_tokens } else { 0 }
                        
                        Write-Host "`n"
                        Write-ChatMessage $aiResponse -Type AI
                    }
                    else {
                        Write-ChatMessage "Error: User message was empty, cannot process request" -Type Error
                        Write-Verbose "DEBUG: currentUserMessage was empty or whitespace"
                        continue
                    }
                }
            }
            else {
                # Use full conversation history for non-streaming mode
                # Build the complete message array for the API call
                $apiMessages = @()
                foreach ($entry in $script:ChatHistory) {
                    $apiMessages += @{
                        role    = $entry.Role
                        content = $entry.Content
                    }
                }
                
                # Use the internal function to maintain conversation context
                $apiResponse = Invoke-ChatAPIRequest -Messages $apiMessages -Model $script:ChatSession.Model -MaxTokens $script:ChatSession.MaxTokens -Temperature $script:ChatSession.Temperature
                $aiResponse = $apiResponse.choices[0].message.content
                $tokensUsed = if ($apiResponse.usage) { $apiResponse.usage.total_tokens } else { 0 }
                
                Write-Host "`n"
                Write-ChatMessage $aiResponse -Type AI
            }
            
            # Add AI response to history
            Add-ChatHistoryEntry -Role 'assistant' -Content $aiResponse
            
            # Update session statistics
            $script:ChatSession.TotalTokens += $tokensUsed
            if ($apiResponse -and $apiResponse.usage) {
                Update-SessionCost -PromptTokens $apiResponse.usage.prompt_tokens -CompletionTokens $apiResponse.usage.completion_tokens -Model $script:ChatSession.Model
            }
            
            # Show token usage if enabled
            if ($script:ChatConfig.ShowTokenUsage -and $tokensUsed -gt 0) {
                Write-Host "`n[$tokensUsed tokens]" -ForegroundColor $script:ChatConfig.InfoColor
            }
            
            Write-Host ""
        }
        catch {
            Write-ChatMessage "Error during chat: $($_.Exception.Message)" -Type Error
        }
    }
    
    # Session cleanup
    if ($script:ChatConfig.AutoSave -and $script:ChatHistory.Count -gt 0) {
        $autoSaveFile = "chat-session-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
        try {
            Save-OpenRouterChatHistory -FilePath $autoSaveFile
            Write-ChatMessage "Session auto-saved to: $autoSaveFile" -Type Info
        }
        catch {
            Write-ChatMessage "Failed to auto-save session: $($_.Exception.Message)" -Type Error
        }
    }
}

function Get-OpenRouterChatHistory {
    <#
    .SYNOPSIS
        Retrieves the current chat session history
    
    .DESCRIPTION
        Returns the conversation history from the current or most recent chat session
    
    .PARAMETER Format
        Output format for the history (Object, Text, or JSON)
    
    .EXAMPLE
        Get-OpenRouterChatHistory
        
    .EXAMPLE
        Get-OpenRouterChatHistory -Format Text
        
    .OUTPUTS
        Array of chat history entries or formatted text
    #>
    [CmdletBinding()]
    param(
        [ValidateSet('Object', 'Text', 'JSON')]
        [string]$Format = 'Object'
    )
    
    if ($Format -eq 'Object') {
        return $script:ChatHistory
    }
    elseif ($Format -eq 'JSON') {
        return ($script:ChatHistory | ConvertTo-Json -Depth 10)
    }
    else {
        # Text format
        $output = @()
        foreach ($entry in $script:ChatHistory) {
            $timestamp = $entry.Timestamp.ToString('yyyy-MM-dd HH:mm:ss')
            $role = $entry.Role.ToUpper()
            $output += "[$timestamp] $role`: $($entry.Content)"
        }
        return $output -join "`n`n"
    }
}

function Save-OpenRouterChatHistory {
    <#
    .SYNOPSIS
        Saves the current chat history to a file
    
    .DESCRIPTION
        Exports the conversation history to a JSON or text file
    
    .PARAMETER FilePath
        Path where to save the chat history
    
    .PARAMETER Format
        File format (JSON or Text)
    
    .EXAMPLE
        Save-OpenRouterChatHistory -FilePath 'my-chat.json'
        
    .EXAMPLE
        Save-OpenRouterChatHistory -FilePath 'my-chat.txt' -Format Text
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,
        
        [ValidateSet('JSON', 'Text')]
        [string]$Format = 'JSON'
    )
    
    if ($script:ChatHistory.Count -eq 0) {
        Write-Warning "No chat history to save"
        return
    }
    
    try {
        $directory = Split-Path -Path $FilePath -Parent
        if ($directory -and -not (Test-Path -Path $directory)) {
            New-Item -Path $directory -ItemType Directory -Force | Out-Null
        }
        
        if ($Format -eq 'JSON') {
            $script:ChatHistory | ConvertTo-Json -Depth 10 | Out-File -FilePath $FilePath -Encoding UTF8
        }
        else {
            $textHistory = Get-OpenRouterChatHistory -Format Text
            $textHistory | Out-File -FilePath $FilePath -Encoding UTF8
        }
        
        Write-Verbose "Chat history saved to: $FilePath"
    }
    catch {
        throw "Failed to save chat history: $($_.Exception.Message)"
    }
}

function Clear-OpenRouterChatHistory {
    <#
    .SYNOPSIS
        Clears the current chat session history
    
    .DESCRIPTION
        Resets the conversation history for the current session
    
    .EXAMPLE
        Clear-OpenRouterChatHistory
    #>
    [CmdletBinding()]
    param()
    
    $script:ChatHistory = @()
    $script:ChatSession.MessageCount = 0
    $script:ChatSession.TotalTokens = 0
    $script:ChatSession.TotalCost = 0.0
    
    # Re-add system prompt if it exists
    if ($script:ChatSession.SystemPrompt) {
        Add-ChatHistoryEntry -Role 'system' -Content $script:ChatSession.SystemPrompt
    }
    
    Write-Verbose "Chat history cleared"
}

function Set-OpenRouterChatConfig {
    <#
    .SYNOPSIS
        Configures chat session settings
    
    .DESCRIPTION
        Updates configuration options for chat sessions including colors, behavior, and limits
    
    .PARAMETER StreamingEnabled
        Enable or disable streaming responses
    
    .PARAMETER ShowTimestamps
        Show timestamps with messages
    
    .PARAMETER ShowTokenUsage
        Display token usage after each response
    
    .PARAMETER ShowCost
        Display cost information
    
    .PARAMETER MaxHistoryLength
        Maximum number of messages to keep in history
    
    .PARAMETER AutoSave
        Automatically save sessions when they end
    
    .PARAMETER BudgetLimit
        Set a budget limit for the session (0 = no limit)
    
    .EXAMPLE
        Set-OpenRouterChatConfig -StreamingEnabled $true -ShowTimestamps $true
        
    .EXAMPLE
        Set-OpenRouterChatConfig -BudgetLimit 5.00 -MaxHistoryLength 50
    #>
    [CmdletBinding()]
    param(
        [bool]$StreamingEnabled,
        [bool]$ShowTimestamps,
        [bool]$ShowTokenUsage,
        [bool]$ShowCost,
        [ValidateRange(10, 1000)]
        [int]$MaxHistoryLength,
        [bool]$AutoSave,
        [ValidateRange(0.0, 1000.0)]
        [decimal]$BudgetLimit
    )
    
    if ($PSBoundParameters.ContainsKey('StreamingEnabled')) {
        $script:ChatConfig.StreamingEnabled = $StreamingEnabled
    }
    if ($PSBoundParameters.ContainsKey('ShowTimestamps')) {
        $script:ChatConfig.ShowTimestamps = $ShowTimestamps
    }
    if ($PSBoundParameters.ContainsKey('ShowTokenUsage')) {
        $script:ChatConfig.ShowTokenUsage = $ShowTokenUsage
    }
    if ($PSBoundParameters.ContainsKey('ShowCost')) {
        $script:ChatConfig.ShowCost = $ShowCost
    }
    if ($PSBoundParameters.ContainsKey('MaxHistoryLength')) {
        $script:ChatConfig.MaxHistoryLength = $MaxHistoryLength
    }
    if ($PSBoundParameters.ContainsKey('AutoSave')) {
        $script:ChatConfig.AutoSave = $AutoSave
    }
    if ($PSBoundParameters.ContainsKey('BudgetLimit')) {
        $script:ChatConfig.BudgetLimit = $BudgetLimit
    }
    
    Write-Verbose "Chat configuration updated"
}

function Get-OpenRouterChatConfig {
    <#
    .SYNOPSIS
        Gets the current chat configuration
    
    .DESCRIPTION
        Returns the current chat session configuration settings
    
    .EXAMPLE
        Get-OpenRouterChatConfig
        
    .OUTPUTS
        Hashtable with current configuration values
    #>
    [CmdletBinding()]
    param()
    
    return $script:ChatConfig.Clone()
}

# Create aliases
New-Alias -Name 'orchat-session' -Value 'Start-OpenRouterChat' -Description 'Short alias for Start-OpenRouterChat'
New-Alias -Name 'orchat-history' -Value 'Get-OpenRouterChatHistory' -Description 'Short alias for Get-OpenRouterChatHistory'
New-Alias -Name 'orchat-save' -Value 'Save-OpenRouterChatHistory' -Description 'Short alias for Save-OpenRouterChatHistory'
New-Alias -Name 'orchat-clear' -Value 'Clear-OpenRouterChatHistory' -Description 'Short alias for Clear-OpenRouterChatHistory'
New-Alias -Name 'orchat-config' -Value 'Set-OpenRouterChatConfig' -Description 'Short alias for Set-OpenRouterChatConfig'

# Export functions and aliases
Export-ModuleMember -Function @(
    'Start-OpenRouterChat',
    'Get-OpenRouterChatHistory',
    'Save-OpenRouterChatHistory', 
    'Clear-OpenRouterChatHistory',
    'Set-OpenRouterChatConfig',
    'Get-OpenRouterChatConfig'
) -Alias @(
    'orchat-session',
    'orchat-history',
    'orchat-save',
    'orchat-clear',
    'orchat-config'
)

Write-Verbose 'OpenRouterAIPS.Chat module loaded successfully'
