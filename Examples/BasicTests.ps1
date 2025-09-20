#Requires -Version 5.1

<#
.SYNOPSIS
    Basic functionality tests for OpenRouterAIPS PowerShell module
    
.DESCRIPTION
    Simple tests to verify that the OpenRouterAIPS module functions work correctly
    
.NOTES
    This is not a comprehensive test suite, but basic validation
    Set OPENROUTER_API_KEY environment variable before running
#>

# Import the module
Import-Module "$PSScriptRoot\..\Source\OpenRouterAIPS.psm1" -Force

# Test results tracking
$script:TestResults = @()

function Add-TestResult {
    param(
        [string]$TestName,
        [bool]$Passed,
        [string]$Details = ""
    )
    
    $script:TestResults += [PSCustomObject]@{
        TestName = $TestName
        Passed = $Passed
        Details = $Details
        Timestamp = Get-Date
    }
    
    $status = if ($Passed) { "PASS" } else { "FAIL" }
    $color = if ($Passed) { "Green" } else { "Red" }
    
    Write-Host "[$status] $TestName" -ForegroundColor $color
    if ($Details -and -not $Passed) {
        Write-Host "       $Details" -ForegroundColor Yellow
    }
}

Write-Host "OpenRouterAIPS Module Tests" -ForegroundColor Cyan
Write-Host "===========================" -ForegroundColor Cyan
Write-Host

# Test 1: Module Import
try {
    $module = Get-Module OpenRouterAIPS
    Add-TestResult -TestName "Module Import" -Passed ($null -ne $module)
}
catch {
    Add-TestResult -TestName "Module Import" -Passed $false -Details $_.Exception.Message
}

# Test 2: Function Availability
$requiredFunctions = @(
    'Invoke-OpenRouterChat',
    'Get-OpenRouterModels',
    'Get-OpenRouterConfig',
    'Set-OpenRouterConfig',
    'Test-OpenRouterConnection'
)

foreach ($func in $requiredFunctions) {
    $available = Get-Command $func -ErrorAction SilentlyContinue
    Add-TestResult -TestName "Function: $func" -Passed ($null -ne $available)
}

# Test 3: Aliases
$requiredAliases = @('orchat', 'ormodels')
foreach ($alias in $requiredAliases) {
    $available = Get-Alias $alias -ErrorAction SilentlyContinue
    Add-TestResult -TestName "Alias: $alias" -Passed ($null -ne $available)
}

# Test 4: Configuration Function
try {
    $config = Get-OpenRouterConfig
    $hasRequiredProps = $config.PSObject.Properties.Name -contains 'ApiKeySet' -and
                       $config.PSObject.Properties.Name -contains 'DefaultModel'
    Add-TestResult -TestName "Get-OpenRouterConfig" -Passed $hasRequiredProps
}
catch {
    Add-TestResult -TestName "Get-OpenRouterConfig" -Passed $false -Details $_.Exception.Message
}

# Test 5: Environment Variable Check
$apiKeySet = -not [string]::IsNullOrEmpty($env:OPENROUTER_API_KEY)
Add-TestResult -TestName "OPENROUTER_API_KEY Environment Variable" -Passed $apiKeySet -Details $(if(-not $apiKeySet) { "Environment variable not set" })

# API Tests (only if API key is available)
if ($apiKeySet) {
    Write-Host
    Write-Host "Running API Tests (requires valid API key)..." -ForegroundColor Yellow
    
    # Test 6: API Connection
    try {
        $connectionResult = Test-OpenRouterConnection
        Add-TestResult -TestName "API Connection Test" -Passed $connectionResult
    }
    catch {
        Add-TestResult -TestName "API Connection Test" -Passed $false -Details $_.Exception.Message
    }
    
    # Test 7: Get Models (basic)
    try {
        $models = Get-OpenRouterModels | Select-Object -First 1
        $hasModels = $models -and ($models -is [array] -and $models.Count -gt 0) -or ($models -is [PSCustomObject])
        Add-TestResult -TestName "Get Models Basic" -Passed $hasModels
    }
    catch {
        Add-TestResult -TestName "Get Models Basic" -Passed $false -Details $_.Exception.Message
    }
    
    # Test 8: Model Filtering
    try {
        $filteredModels = Get-OpenRouterModels -Filter 'gpt'
        $hasFilteredModels = $filteredModels -and $filteredModels.Count -gt 0
        Add-TestResult -TestName "Model Filtering" -Passed $hasFilteredModels
    }
    catch {
        Add-TestResult -TestName "Model Filtering" -Passed $false -Details $_.Exception.Message
    }
    
    # Test 9: Simple Chat Request
    try {
        $chatResponse = Invoke-OpenRouterChat -Message "Say 'test successful'" -MaxTokens 10
        $hasContent = -not [string]::IsNullOrEmpty($chatResponse.Content)
        $hasUsage = $chatResponse.Usage -and $chatResponse.Usage.TotalTokens -gt 0
        Add-TestResult -TestName "Simple Chat Request" -Passed ($hasContent -and $hasUsage)
    }
    catch {
        Add-TestResult -TestName "Simple Chat Request" -Passed $false -Details $_.Exception.Message
    }
    
    # Test 10: Pipeline Input
    try {
        $pipelineResult = "Hello" | Invoke-OpenRouterChat -MaxTokens 20
        $pipelineWorked = -not [string]::IsNullOrEmpty($pipelineResult.Content)
        Add-TestResult -TestName "Pipeline Input" -Passed $pipelineWorked
    }
    catch {
        Add-TestResult -TestName "Pipeline Input" -Passed $false -Details $_.Exception.Message
    }
}
else {
    Write-Host
    Write-Host "Skipping API tests - OPENROUTER_API_KEY not set" -ForegroundColor Yellow
}

# Test 11: Configuration Changes
try {
    $originalConfig = Get-OpenRouterConfig
    Set-OpenRouterConfig -DefaultMaxTokens 1500
    $newConfig = Get-OpenRouterConfig
    $configChanged = $newConfig.DefaultMaxTokens -eq 1500
    
    # Restore original settings
    Set-OpenRouterConfig -DefaultMaxTokens $originalConfig.DefaultMaxTokens
    
    Add-TestResult -TestName "Configuration Changes" -Passed $configChanged
}
catch {
    Add-TestResult -TestName "Configuration Changes" -Passed $false -Details $_.Exception.Message
}

# Display Results Summary
Write-Host
Write-Host "Test Results Summary" -ForegroundColor Cyan
Write-Host "===================" -ForegroundColor Cyan

$passedTests = ($script:TestResults | Where-Object { $_.Passed }).Count
$totalTests = $script:TestResults.Count
$failedTests = $totalTests - $passedTests

Write-Host "Total Tests: $totalTests" -ForegroundColor White
Write-Host "Passed: $passedTests" -ForegroundColor Green
Write-Host "Failed: $failedTests" -ForegroundColor $(if ($failedTests -eq 0) { 'Green' } else { 'Red' })

if ($failedTests -gt 0) {
    Write-Host
    Write-Host "Failed Tests:" -ForegroundColor Red
    $script:TestResults | Where-Object { -not $_.Passed } | ForEach-Object {
        Write-Host "  - $($_.TestName): $($_.Details)" -ForegroundColor Yellow
    }
}

# Overall result
$overallSuccess = $failedTests -eq 0
Write-Host
Write-Host "Overall Test Result: $(if ($overallSuccess) { 'SUCCESS' } else { 'SOME FAILURES' })" -ForegroundColor $(if ($overallSuccess) { 'Green' } else { 'Yellow' })

if (-not $apiKeySet) {
    Write-Host
    Write-Host "Note: API tests were skipped. To run full tests:" -ForegroundColor Gray
    Write-Host "1. Set environment variable: `$env:OPENROUTER_API_KEY = 'your-api-key'" -ForegroundColor Gray
    Write-Host "2. Run this test script again" -ForegroundColor Gray
}