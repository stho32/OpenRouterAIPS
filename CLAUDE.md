# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

OpenRouterAIPS is a PowerShell module that provides command-line access to AI models through OpenRouter's unified API. The module is designed for PowerShell 5.1+ compatibility and follows PowerShell best practices with proper cmdlet naming, parameter validation, and pipeline support.

## Tech Stack

- **Language**: PowerShell (5.1+)
- **Architecture**: powershell-module
- **API**: OpenRouter (OpenAI-compatible REST API)
- **Testing**: Pester (if available), PSScriptAnalyzer (linting)

## Development Commands

### Import Module
```powershell
Import-Module ".\Source\OpenRouterAIPS.psm1" -Force
```

### Run Tests
```powershell
# Run Pester tests (if available)
Invoke-Pester -Path .\Tests\ -Output Detailed

# Run basic functionality tests
.\Examples\BasicTests.ps1

# Lint with PSScriptAnalyzer
Invoke-ScriptAnalyzer -Path .\Source\ -Recurse -ReportSummary
```

### Reload Module After Changes
```powershell
Remove-Module OpenRouterAIPS -Force; Import-Module ".\Source\OpenRouterAIPS.psm1" -Force
```

### Prerequisites
- Set `OPENROUTER_API_KEY` environment variable before testing
- PowerShell 5.1 or higher required
- Internet connection for API calls

## Architecture

### Core Module Structure
- **Source/OpenRouterAIPS.psm1** - Main module file containing all functions and private helpers
- **Source/OpenRouterAIPS.psd1** - Module manifest with metadata and exports
- **Source/OpenRouterAIPS.Chat.psm1** - Interactive chat terminal functionality
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
- `Invoke-OpenRouterApiRequest` - Makes HTTP requests with error handling

## Conventions

- Use `Verb-Noun` naming for all PowerShell functions (approved verbs only)
- All public functions must have comment-based help (`.SYNOPSIS`, `.DESCRIPTION`, `.PARAMETER`, `.EXAMPLE`)
- Use `[CmdletBinding()]` on all functions
- Validate parameters with `[ValidateNotNullOrEmpty()]`, `[Parameter(Mandatory)]`, etc.
- Use `$ErrorActionPreference = 'Stop'` at module level for fail-fast behavior
- Return structured `PSCustomObject` instances, not raw strings
- Support pipeline input where appropriate
- Handle errors with try-catch and meaningful error messages
- UTF-8 encoding for international character support
