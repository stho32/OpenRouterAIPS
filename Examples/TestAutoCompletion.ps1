#Requires -Version 5.1

<#
.SYNOPSIS
    Test script to demonstrate the auto-completion functionality for Model parameter
    
.DESCRIPTION
    This script shows how the auto-completion works for the Model parameter in OpenRouterAIPS
    
.NOTES
    Run this script and then test tab completion manually in the console
#>

# Import the module
Import-Module "$PSScriptRoot\..\Source\OpenRouterAIPS.psm1" -Force

Write-Host "OpenRouterAIPS Auto-Completion Test" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host

Write-Host "The Model parameter now supports auto-completion!" -ForegroundColor Green
Write-Host "Try typing one of these commands and press TAB after the quote:" -ForegroundColor Yellow
Write-Host

Write-Host "Examples to try:" -ForegroundColor White
Write-Host "  Invoke-OpenRouterChat -Message 'test' -Model 'openai<TAB>" -ForegroundColor Gray
Write-Host "  orchat 'hello' -Model 'anthropic<TAB>" -ForegroundColor Gray  
Write-Host "  Set-OpenRouterConfig -DefaultModel 'gpt<TAB>" -ForegroundColor Gray
Write-Host

Write-Host "Available model providers:" -ForegroundColor White
try {
    $models = Get-OpenRouterModels
    $providers = $models | Group-Object Provider | Sort-Object Name
    $providers | ForEach-Object {
        Write-Host "  - $($_.Name) ($($_.Count) models)" -ForegroundColor Gray
    }
}
catch {
    Write-Warning "Could not retrieve models for preview. Auto-completion will use fallback models."
}

Write-Host
Write-Host "Auto-completion features:" -ForegroundColor White
Write-Host "  - Shows up to 20 matching models" -ForegroundColor Gray
Write-Host "  - Includes provider, name, and context length in tooltip" -ForegroundColor Gray
Write-Host "  - Falls back to common models if API is unavailable" -ForegroundColor Gray
Write-Host "  - Works with both full commands and aliases" -ForegroundColor Gray
Write-Host

Write-Host "Test the auto-completion by typing commands above in the console!" -ForegroundColor Green

# Manual testing function
function Test-AutoCompletion {
    param(
        [string]$TestString
    )
    
    Write-Host "Testing completion for: $TestString" -ForegroundColor Yellow
    
    try {
        $result = TabExpansion2 $TestString $TestString.Length
        if ($result.CompletionMatches) {
            Write-Host "Found $($result.CompletionMatches.Count) completions:" -ForegroundColor Green
            $result.CompletionMatches | Select-Object -First 5 | ForEach-Object {
                Write-Host "  $($_.CompletionText)" -ForegroundColor Gray
            }
        } else {
            Write-Host "No completions found" -ForegroundColor Red
        }
    }
    catch {
        Write-Host "Error testing completion: $($_.Exception.Message)" -ForegroundColor Red
    }
    Write-Host
}

# Run some automated tests
Write-Host "Automated completion tests:" -ForegroundColor Cyan
Test-AutoCompletion "Invoke-OpenRouterChat -Message 'test' -Model 'openai"
Test-AutoCompletion "orchat 'hello' -Model 'anthropic"
Test-AutoCompletion "Set-OpenRouterConfig -DefaultModel 'gpt"