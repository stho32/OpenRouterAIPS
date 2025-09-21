# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenRouterAIPS is a PowerShell module that provides command-line access to AI models through OpenRouter's unified API. The module is designed for PowerShell 5.1+ compatibility and follows PowerShell best practices with proper cmdlet naming, parameter validation, and pipeline support.

## Development Commands

### Testing
```powershell
# Run basic functionality tests
.\Examples\BasicTests.ps1

# Test specific functionality
.\Examples\BasicUsage.ps1
.\Examples\TestAutoCompletion.ps1
.\Examples\TestEncoding.ps1
```

### Module Development
```powershell
# Import module for development/testing
Import-Module ".\Source\OpenRouterAIPS.psm1" -Force

# Reload module after changes
Remove-Module OpenRouterAIPS -Force; Import-Module ".\Source\OpenRouterAIPS.psm1" -Force

# Test API connectivity
Test-OpenRouterConnection
```

### Prerequisites
- Set `OPENROUTER_API_KEY` environment variable before testing
- PowerShell 5.1 or higher required
- Internet connection for API calls

## Architecture

### Core Module Structure
- **Source/OpenRouterAIPS.psm1** - Main module file containing all functions and private helpers
- **Source/OpenRouterAIPS.psd1** - Module manifest with metadata and exports
- **Examples/** - Test scripts and usage examples
- **Documentation/** - API documentation and guides
- **requirements/** - Project requirements specifications

### Key Functions
The module exports these primary cmdlets:
- `Invoke-OpenRouterChat` (alias: `orchat`) - Send messages to AI models
- `Get-OpenRouterModels` (alias: `ormodels`) - Retrieve available models
- `Get-OpenRouterConfig` / `Set-OpenRouterConfig` - Manage default settings
- `Test-OpenRouterConnection` - Verify API connectivity

### Private Helper Functions
- `Get-OpenRouterApiKey` - Retrieves API key from environment
- `New-OpenRouterHeaders` - Creates HTTP headers for API requests
- `ConvertTo-TerminalEncoding` - Handles UTF-8 text encoding for terminals
- `Invoke-OpenRouterApiRequest` - Makes HTTP requests with error handling

### Configuration System
The module uses script-level variables for defaults:
- `$script:DefaultModel` - Default AI model (openai/gpt-3.5-turbo)
- `$script:DefaultMaxTokens` - Default token limit (1000)
- `$script:DefaultTemperature` - Default temperature (0.7)

### API Integration
- Base URI: `https://openrouter.ai/api/v1`
- Authentication via Bearer token from `OPENROUTER_API_KEY`
- OpenAI-compatible API format
- Comprehensive error handling for network and API errors

## Development Patterns

### Error Handling
All functions use try-catch blocks with meaningful error messages. API errors are converted to PowerShell exceptions with context about the failure.

### Pipeline Support
Functions accept pipeline input where appropriate, particularly `Invoke-OpenRouterChat` which can process arrays of messages.

### Parameter Validation
All public functions use proper PowerShell parameter attributes like `[Parameter()]`, `[ValidateNotNullOrEmpty()]`, and support for tab completion.

### Encoding Handling
The module includes UTF-8 encoding support for international characters, converting text appropriately for the current terminal encoding.

### Object Output
Functions return structured PSCustomObject instances with consistent properties, enabling PowerShell's object pipeline features.

## Testing Strategy

Run `.\Examples\BasicTests.ps1` to verify:
- Module loading and function availability
- Configuration management
- API connectivity (requires valid API key)
- Basic chat functionality
- Error handling scenarios

The test script provides pass/fail results and tracks test execution details.

## Requirements Implementation

This module implements all requirements from `requirements/R001 init requirements.md`:
- **R001.1**: Secure API integration with OpenRouter
- **R001.2**: PowerShell cmdlets with parameter and pipeline support
- **R001.3**: Environment variable configuration management
- **R001.4**: Structured PowerShell object output
- **R001.5**: Comprehensive error handling with verbose logging

Technical constraints are met: PowerShell 5.1+ compatibility, no external dependencies, Windows-focused implementation with clean code style.