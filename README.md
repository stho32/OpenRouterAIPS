# OpenRouterAIPS

A PowerShell module for interacting with OpenRouter AI API to provide command-line tools for AI model access.

## Overview

OpenRouterAIPS enables PowerShell users to interact with various AI models through OpenRouter's unified API. This module provides simple cmdlets for chat completions, model discovery, and configuration management.

## Features

- **Multiple AI Models**: Access GPT, Claude, Gemini, and other AI models through a single interface
- **PowerShell Native**: Designed specifically for PowerShell with proper parameter validation and pipeline support
- **Auto-Completion**: Intelligent tab completion for AI model names with live API data
- **Secure Authentication**: Uses environment variables for API key storage
- **Rich Output**: Returns structured PowerShell objects with usage statistics
- **Error Handling**: Comprehensive error handling with meaningful messages
- **Configuration Management**: Customizable default settings
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

## Troubleshooting

### Common Issues

**"API key not found" error:**
- Ensure `OPENROUTER_API_KEY` environment variable is set
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

This project implements the requirements specified in `requirements\R001 init requirements.md`. All core functionality has been implemented according to the technical constraints.

## License

Copyright (c) 2025 OpenRouterAIPS. All rights reserved.

## API Documentation

For detailed API information, see `Documentation\openrouter-api.md`.

---

*For more information about OpenRouter, visit [openrouter.ai](https://openrouter.ai)*