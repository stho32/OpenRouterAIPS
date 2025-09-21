#Requires -Version 5.1

<#
.SYNOPSIS
    Basic usage examples for OpenRouterAIPS PowerShell module
    
.DESCRIPTION
    This script demonstrates how to use the OpenRouterAIPS module to interact with AI models
    
.NOTES
    Before running this script, make sure to:
    1. Set the OPENROUTER_API_KEY environment variable
    2. Import the OpenRouterAIPS module
#>

# Import the module (adjust path as needed)
Import-Module "$PSScriptRoot\..\Source\OpenRouterAIPS.psm1" -Force

Write-Host "OpenRouterAIPS Basic Usage Examples" -ForegroundColor Cyan
Write-Host "====================================" -ForegroundColor Cyan
Write-Host

# Example 1: Test connection
Write-Host "1. Testing OpenRouter API connection..." -ForegroundColor Yellow
$connectionTest = Test-OpenRouterConnection -Verbose
Write-Host "Connection test result: $connectionTest" -ForegroundColor $(if($connectionTest) { 'Green' } else { 'Red' })
Write-Host

# Example 2: Get current configuration
Write-Host "2. Current OpenRouterAIPS configuration:" -ForegroundColor Yellow
$config = Get-OpenRouterConfig
$config | Format-List
Write-Host

# Example 3: Get available models (limited to first 5 for demo)
Write-Host "3. Getting available AI models (showing first 5)..." -ForegroundColor Yellow
try {
    $models = Get-OpenRouterModels | Select-Object -First 5
    $models | Format-Table Id, Provider, ContextLength, PromptPrice -AutoSize
}
catch {
    Write-Warning "Could not retrieve models: $($_.Exception.Message)"
}
Write-Host

# Example 4: Search for specific models
Write-Host "4. Searching for GPT models..." -ForegroundColor Yellow
try {
    $gptModels = Get-OpenRouterModels -Filter 'gpt' | Select-Object -First 3
    $gptModels | Format-Table Id, Provider, ContextLength -AutoSize
}
catch {
    Write-Warning "Could not search models: $($_.Exception.Message)"
}
Write-Host

# Example 5: Simple chat interaction
Write-Host "5. Simple chat interaction..." -ForegroundColor Yellow
try {
    $response = Invoke-OpenRouterChat -Message "Hello! Please respond with exactly 10 words."
    Write-Host "AI Response: $($response.Content)" -ForegroundColor Green
    Write-Host "Model Used: $($response.Model)" -ForegroundColor Gray
    Write-Host "Tokens Used: $($response.Usage.TotalTokens)" -ForegroundColor Gray
}
catch {
    Write-Warning "Could not complete chat request: $($_.Exception.Message)"
}
Write-Host

# Example 6: Chat with custom model and parameters
Write-Host "6. Chat with custom parameters..." -ForegroundColor Yellow
try {
    $response = Invoke-OpenRouterChat -Message "Write a haiku about PowerShell" -MaxTokens 100 -Temperature 0.9
    Write-Host "AI Response:" -ForegroundColor Green
    Write-Host $response.Content -ForegroundColor White
    Write-Host "Usage: $($response.Usage.TotalTokens) tokens" -ForegroundColor Gray
}
catch {
    Write-Warning "Could not complete custom chat request: $($_.Exception.Message)"
}
Write-Host

# Example 7: Pipeline usage
Write-Host "7. Using pipeline input..." -ForegroundColor Yellow
try {
    $questions = @(
        "What is 2+2?",
        "Name one programming language"
    )
    
    $responses = $questions | Invoke-OpenRouterChat -MaxTokens 50
    for ($i = 0; $i -lt $questions.Count; $i++) {
        Write-Host "Q: $($questions[$i])" -ForegroundColor Cyan
        Write-Host "A: $($responses[$i].Content.Trim())" -ForegroundColor White
        Write-Host
    }
}
catch {
    Write-Warning "Could not complete pipeline requests: $($_.Exception.Message)"
}

# Example 8: Using aliases
Write-Host "8. Using command aliases..." -ForegroundColor Yellow
try {
    Write-Host "Available models using 'ormodels' alias:" -ForegroundColor Gray
    $aliasModels = ormodels -Filter 'claude' | Select-Object -First 2
    $aliasModels | Format-Table Id, Provider -AutoSize
    
    Write-Host "Chat using 'orchat' alias:" -ForegroundColor Gray
    $aliasResponse = orchat "Say 'hello' in three different languages"
    Write-Host $aliasResponse.Content -ForegroundColor White
}
catch {
    Write-Warning "Could not use aliases: $($_.Exception.Message)"
}
Write-Host

# Example 9: Configuration changes
Write-Host "9. Changing default configuration..." -ForegroundColor Yellow
Write-Host "Setting new defaults..." -ForegroundColor Gray
Set-OpenRouterConfig -DefaultMaxTokens 500 -DefaultTemperature 0.5

Write-Host "New configuration:" -ForegroundColor Gray
Get-OpenRouterConfig | Format-List DefaultMaxTokens, DefaultTemperature

Write-Host
Write-Host "Examples completed!" -ForegroundColor Green
Write-Host "For more advanced usage, see the function help:" -ForegroundColor Gray
Write-Host "  Get-Help Invoke-OpenRouterChat -Full" -ForegroundColor Gray
Write-Host "  Get-Help Get-OpenRouterModels -Full" -ForegroundColor Gray