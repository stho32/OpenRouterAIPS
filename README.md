# OpenRouterAIPS

A PowerShell module for interacting with OpenRouter AI API to provide command-line tools for AI model access.

## Overview

OpenRouterAIPS enables PowerShell users to interact with various AI models through OpenRouter's unified API. This module provides simple cmdlets for chat completions, model discovery, and configuration management.

## Features

- **Multiple AI Models**: Access GPT, Claude, Gemini, and other AI models through a single interface
- **PowerShell Native**: Designed specifically for PowerShell with proper parameter validation and pipeline support
- **Interactive Chat Terminal**: Full-featured chat session with streaming responses and conversation history
- **Full Conversation Context**: AI remembers entire conversation history, enabling natural multi-turn dialogues
- **Streaming Responses**: Real-time AI responses displayed as they're generated
- **Auto-Completion**: Intelligent tab completion for AI model names with live API data
- **Chat History Management**: Save, load, and manage conversation history
- **Session Commands**: Built-in commands for model switching, history management, and configuration
- **Secure Authentication**: Uses environment variables for API key storage
- **Rich Output**: Returns structured PowerShell objects with usage statistics
- **Error Handling**: Comprehensive error handling with meaningful messages
- **Configuration Management**: Customizable default settings and chat preferences
- **Command Aliases**: Short aliases for frequent commands

## Requirements

- PowerShell 5.1 or higher
- OpenRouter API key (sign up at [openrouter.ai](https://openrouter.ai))
- Internet connection

## Installation

1. Clone or download this repository
2. Set your OpenRouter API key as an environment variable:
   ```powershell
   $env:OPENROUTER_API_KEY = "your-api-key-here"
   ```
3. Import the module:
   ```powershell
   Import-Module ".\Source\OpenRouterAIPS.psm1"
   ```

## Quick Start

### Basic Chat
```powershell
# Simple chat interaction
Invoke-OpenRouterChat -Message "Hello, how are you?"

# Using the short alias
orchat "What is PowerShell?"

# With streaming enabled
orchat "Explain quantum computing" -Stream
```

### Interactive Chat Terminal
```powershell
# Start an interactive chat session
Start-OpenRouterChat

# Start with a specific model
orchat-session -Model "anthropic/claude-3-sonnet"

# Start with custom configuration
Start-OpenRouterChat -Model "openai/gpt-4" -SystemPrompt "You are a helpful coding assistant"
```

### List Available Models
```powershell
# Get all models
Get-OpenRouterModels

# Search for specific models
Get-OpenRouterModels -Filter "gpt"

# Using alias
ormodels -Filter "claude"
```

### Pipeline Support
```powershell
# Process multiple questions
@("What is 2+2?", "Name a programming language") | Invoke-OpenRouterChat -MaxTokens 50
```

## Available Commands

### Core Commands

#### `Invoke-OpenRouterChat`
Send messages to AI models and receive responses.

**Parameters:**
- `Message` - The message to send (accepts pipeline input)
- `Model` - AI model to use (default: openai/gpt-3.5-turbo)
- `MaxTokens` - Maximum response length (default: 1000)
- `Temperature` - Response randomness 0.0-2.0 (default: 0.7)
- `SystemPrompt` - Optional system prompt for context
- `Stream` - Enable streaming responses (real-time display)

**Alias:** `orchat`

#### `Get-OpenRouterModels`
Retrieve available AI models with pricing and details.

**Parameters:**
- `Filter` - Optional filter to search models by name

**Alias:** `ormodels`

#### `Test-OpenRouterConnection`
Test API connectivity and authentication.

#### `Get-OpenRouterConfig`
Display current module configuration.

#### `Set-OpenRouterConfig`
Modify default settings.

**Parameters:**
- `DefaultModel` - Set default AI model
- `DefaultMaxTokens` - Set default token limit
- `DefaultTemperature` - Set default temperature

### Chat Terminal Commands

#### `Start-OpenRouterChat`
Launch an interactive chat session with streaming responses and full conversation management.

**Parameters:**
- `Model` - AI model to use (supports tab completion)
- `SystemPrompt` - Optional system prompt for the session
- `MaxTokens` - Maximum tokens per response (default: 1000)
- `Temperature` - Response randomness 0.0-2.0 (default: 0.7)
- `NoStreaming` - Disable streaming for traditional request/response

**Alias:** `orchat-session`

#### `Get-OpenRouterChatHistory`
Retrieve current conversation history.

**Alias:** `orchat-history`

#### `Save-OpenRouterChatHistory`
Save conversation history to a file.

**Parameters:**
- `FilePath` - Path to save the conversation
- `Format` - Export format (JSON, Text, Markdown)

**Alias:** `orchat-save`

#### `Clear-OpenRouterChatHistory`
Clear the current conversation history.

**Alias:** `orchat-clear`

#### `Set-OpenRouterChatConfig` / `Get-OpenRouterChatConfig`
Configure chat terminal settings like colors, streaming behavior, and display options.

**Alias:** `orchat-config`
- `DefaultModel` - Set default AI model
- `DefaultMaxTokens` - Set default token limit
- `DefaultTemperature` - Set default temperature

## Examples

### Basic Usage
```powershell
# Import module
Import-Module ".\Source\OpenRouterAIPS.psm1"

# Test connection
Test-OpenRouterConnection

# Simple chat
$response = Invoke-OpenRouterChat -Message "Explain quantum computing in simple terms"
Write-Host $response.Content

# View usage statistics
$response.Usage
```

### Advanced Usage
```powershell
# Use different model with custom parameters
$result = Invoke-OpenRouterChat -Message "Write a poem about code" `
    -Model "anthropic/claude-3-sonnet" `
    -MaxTokens 200 `
    -Temperature 0.9 `
    -SystemPrompt "You are a creative poet"

# Process multiple inputs
$questions = Get-Content "questions.txt"
$answers = $questions | Invoke-OpenRouterChat -MaxTokens 100

# Find specific models
$claudeModels = Get-OpenRouterModels -Filter "claude"
$cheapModels = Get-OpenRouterModels | Where-Object { $_.PromptPrice -lt 0.001 }
```

### Auto-Completion
The Model parameter supports intelligent tab completion:
```powershell
# Type and press TAB after the quote to see available models
Invoke-OpenRouterChat -Message "test" -Model "openai<TAB>
orchat "hello" -Model "anthropic<TAB>
Set-OpenRouterConfig -DefaultModel "gpt<TAB>

# Auto-completion features:
# - Shows up to 20 matching models
# - Displays provider, name, and context length
# - Falls back to common models if API unavailable
# - Works with aliases and full command names
```

## Interactive Chat Terminal

The new interactive chat terminal provides a browser-like chat experience in PowerShell with streaming responses and conversation management.

### Starting a Chat Session

```powershell
# Basic chat session
Start-OpenRouterChat

# With specific model
Start-OpenRouterChat -Model "anthropic/claude-3-sonnet"
orchat-session -Model "openai/gpt-4"

# With custom settings
Start-OpenRouterChat -Model "meta-llama/llama-3.2-3b-instruct:free" -SystemPrompt "You are a helpful coding assistant" -MaxTokens 2000
```

### Chat Session Features

#### Real-time Streaming Responses
```
You: Explain how machine learning works

AI: Machine learning is a subset of artificial intelligence that enables computers to learn and improve their performance on a specific task without being explicitly programmed for every scenario...
[Response streams in real-time as it's generated]

[156 tokens] [Cost: $0.0024]
```

#### Session Commands
While in a chat session, you can use special commands starting with `/`:

```powershell
# Core Commands
/help           # Show all available commands
/exit or /quit  # End the chat session
/clear          # Clear conversation history

# Model Management
/model          # Show current model
/model gpt-4    # Switch to a different model
/models         # List available models

# Configuration
/config         # Show current session settings
/stream on      # Enable streaming responses
/stream off     # Disable streaming responses
/system <prompt>  # Set or update system prompt

# History Management
/save filename.json    # Save conversation to file
/cost                  # Show session cost information
/stats                 # Display session statistics
```

#### Example Chat Session
```
Successfully connected to OpenRouter API

+ ============================================================ +
[System]: OpenRouter AI Chat Session Started
[Info]: Model: anthropic/claude-3-sonnet
[Info]: Type '/help' for commands or '/exit' to quit
+ ============================================================ +

You: Hello! Can you help me with PowerShell?
[Info]: Thinking...

AI: Hello! I'd be happy to help you with PowerShell. I can assist with:
- Writing scripts and functions
- Cmdlet usage and parameters
- Object manipulation and pipelines
- Error handling and debugging
- Module development
- Best practices and optimization

What specific PowerShell topic or problem would you like help with?

[89 tokens] [Cost: $0.0013]

You: /model gpt-4
[System]: Switched to model: openai/gpt-4

You: How do I create a custom PowerShell function?
[Info]: Thinking...

AI: To create a custom PowerShell function, use this basic syntax:

```powershell
function FunctionName {
    param(
        [Type]$Parameter1,
        [Type]$Parameter2
    )
    
    # Function body
    # Your code here
    
    return $result
}
```

Here's a practical example:

```powershell
function Get-SystemInfo {
    param(
        [string]$ComputerName = $env:COMPUTERNAME,
        [switch]$IncludeDisks
    )
    
    $info = [PSCustomObject]@{
        Computer = $ComputerName
        OS = (Get-WmiObject -Class Win32_OperatingSystem).Caption
        Memory = [math]::Round((Get-WmiObject -Class Win32_ComputerSystem).TotalPhysicalMemory / 1GB, 2)
    }
    
    if ($IncludeDisks) {
        $info | Add-Member -NotePropertyName Disks -NotePropertyValue (Get-WmiObject -Class Win32_LogicalDisk | Select-Object DeviceID, Size, FreeSpace)
    }
    
    return $info
}
```

[247 tokens] [Cost: $0.0074]

You: /save my-powershell-help.json
[System]: Conversation saved to: my-powershell-help.json

You: /exit
[System]: Chat session ended. Goodbye!
```

### Chat Configuration

#### Viewing Current Configuration
```powershell
Get-OpenRouterChatConfig
```

#### Customizing Chat Settings
```powershell
# Set custom colors and behavior
Set-OpenRouterChatConfig -StreamingEnabled $true -ShowCost $true -ShowTimestamps $true

# Configure display colors
Set-OpenRouterChatConfig -UserColor "Cyan" -AIColor "Green" -SystemColor "Yellow"

# Set budget limits
Set-OpenRouterChatConfig -BudgetLimit 10.00 -BudgetWarningThreshold 0.8
```

#### Available Configuration Options
- `StreamingEnabled` - Enable/disable real-time streaming
- `ShowCost` - Display cost information per response
- `ShowTokenUsage` - Show token count after each response
- `ShowTimestamps` - Include timestamps in messages
- `AutoSave` - Automatically save conversations on exit
- `MaxHistoryLength` - Maximum conversation history to maintain
- `BudgetLimit` - Set spending limit for the session
- `BudgetWarningThreshold` - Warning threshold (0.0-1.0)
- Color settings for different message types

### Managing Chat History

#### Saving Conversations
```powershell
# Save current conversation
Save-OpenRouterChatHistory -FilePath "conversation.json"

# Save in different formats
Save-OpenRouterChatHistory -FilePath "chat.txt" -Format Text
Save-OpenRouterChatHistory -FilePath "chat.md" -Format Markdown

# Using alias
orchat-save "important-conversation.json"
```

#### Viewing History
```powershell
# Get current conversation
$history = Get-OpenRouterChatHistory
$history | Format-Table Role, Content, Timestamp

# Using alias
orchat-history
```

#### Clearing History
```powershell
# Clear current conversation
Clear-OpenRouterChatHistory

# Using alias
orchat-clear
```

### Streaming vs. Non-Streaming Mode

#### Streaming Mode (Default)
- Responses appear in real-time as they're generated
- Better user experience for long responses
- Shows thinking indicator while processing
- Graceful fallback if streaming fails

#### Non-Streaming Mode
```powershell
# Start session without streaming
Start-OpenRouterChat -NoStreaming

# Toggle streaming in session
/stream off    # Disable streaming
/stream on     # Enable streaming
```

### Error Handling and Resilience

The chat terminal includes robust error handling:
- Network timeout recovery
- API rate limiting with automatic retry
- Model switching if current model fails
- Conversation state preservation
- Graceful degradation from streaming to regular mode

### Configuration
```powershell
# View current config
Get-OpenRouterConfig

# Set new defaults
Set-OpenRouterConfig -DefaultModel "anthropic/claude-3-haiku" -DefaultMaxTokens 500

# Check available balance (if supported by your model)
$models = Get-OpenRouterModels
$models | Format-Table Id, PromptPrice, CompletionPrice
```

## Environment Variables

### Required
- `OPENROUTER_API_KEY` - Your OpenRouter API key

### Example Setup
```powershell
# Temporary (current session only)
$env:OPENROUTER_API_KEY = "sk-or-v1-your-key-here"

# Permanent (Windows)
[Environment]::SetEnvironmentVariable("OPENROUTER_API_KEY", "sk-or-v1-your-key-here", "User")
```

## Output Objects

### Chat Response Object
```powershell
[PSCustomObject]@{
    Content = "AI response text"
    Model = "openai/gpt-3.5-turbo"
    FinishReason = "stop"
    Usage = @{
        PromptTokens = 10
        CompletionTokens = 25
        TotalTokens = 35
    }
    Id = "chatcmpl-abc123"
    Created = [DateTime]
}
```

### Model Object
```powershell
[PSCustomObject]@{
    Id = "openai/gpt-3.5-turbo"
    Name = "gpt-3.5-turbo"
    Provider = "openai"
    ContextLength = 4096
    PromptPrice = 0.0015
    CompletionPrice = 0.002
    Created = [DateTime]
}
```

## Error Handling

The module includes comprehensive error handling:

- **API Key Missing**: Clear message when OPENROUTER_API_KEY is not set
- **Network Errors**: Handles connection failures gracefully
- **API Errors**: Meaningful error messages from OpenRouter API
- **Parameter Validation**: Input validation with helpful error messages

## Testing

Run the included test script to verify functionality:

```powershell
.\Examples\BasicTests.ps1
```

This will test:
- Module loading
- Function availability
- Configuration management
- API connectivity (if API key is set)
- Basic chat functionality

## Examples Directory

The `Examples` folder contains:
- `BasicUsage.ps1` - Comprehensive usage examples
- `BasicTests.ps1` - Functionality tests  
- `ChatTerminalUsage.ps1` - Interactive chat session examples
- `TestChatTerminal.ps1` - Chat terminal functionality tests
- `TestAutoCompletion.ps1` - Model auto-completion demonstrations

## Troubleshooting

### Common Issues

**"API key not found" error:**
- Ensure `OPENROUTER_API_KEY` environment variable is set
- Verify the key is valid and has sufficient credits
- Check that the key has proper permissions for the OpenRouter API

**Chat not remembering previous messages:**
- Ensure you're using `Start-OpenRouterChat` for interactive sessions
- Check conversation history with `Get-OpenRouterChatHistory`
- Verify the session hasn't been cleared with `Clear-OpenRouterChatHistory`
- For single API calls, use `Invoke-OpenRouterChat` which doesn't maintain context

**Streaming responses not working:**
- Network connectivity issues can cause streaming to fail
- The module automatically falls back to standard responses
- Try setting `$ChatStreamingMode = $false` to disable streaming
- Check PowerShell execution policy allows the module to run

**Model auto-completion not working:**
- Requires internet connectivity to fetch live model data
- Verify API key has proper permissions
- Try refreshing with a new PowerShell session

**"Cannot bind argument to parameter" errors:**
- Usually indicates internal parameter passing issues
- Try restarting the chat session with `Start-OpenRouterChat`
- Check for any custom variables that might interfere

### Performance Tips

- Use streaming mode for real-time feedback on longer responses
- Clear chat history periodically to reduce API payload size
- Set appropriate max tokens to control response length and cost
- Restart PowerShell after setting environment variable

**"Failed to connect to OpenRouter API" error:**
- Check internet connection
- Verify API key is valid
- Check if OpenRouter service is available

**Module import errors:**
- Ensure PowerShell version is 5.1 or higher
- Check file permissions
- Try importing with `-Force` parameter

## Contributing

This project implements the requirements specified in:
- `requirements\R001 init requirements.md` - Core API functionality
- `requirements\R002 Chat in Terminal.md` - Interactive chat terminal with streaming

All features have been implemented according to the technical constraints and user experience requirements.

## License

Copyright (c) 2025 OpenRouterAIPS. All rights reserved.

## API Documentation

For detailed API information, see `Documentation\openrouter-api.md`.

---

*For more information about OpenRouter, visit [openrouter.ai](https://openrouter.ai)*