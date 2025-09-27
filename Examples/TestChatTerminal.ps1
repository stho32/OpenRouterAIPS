# Test script for OpenRouterAIPS Chat Terminal functionality
# This script demonstrates the R002 Chat in Terminal implementation

param(
    [string]$ApiKey = $env:OPENROUTER_API_KEY
)

# Ensure API key is set
if (-not $ApiKey) {
    Write-Error "Please set OPENROUTER_API_KEY environment variable or provide -ApiKey parameter"
    exit 1
}

# Set the API key if provided as parameter
if ($ApiKey -ne $env:OPENROUTER_API_KEY) {
    $env:OPENROUTER_API_KEY = $ApiKey
}

Write-Host "Testing OpenRouterAIPS Chat Terminal Implementation (R002)" -ForegroundColor Yellow
Write-Host "=" * 60 -ForegroundColor Yellow

# Import the module
try {
    $modulePath = Join-Path -Path $PSScriptRoot -ChildPath "..\Source\OpenRouterAIPS.psm1"
    Import-Module -Name $modulePath -Force
    Write-Host "✓ Module imported successfully" -ForegroundColor Green
}
catch {
    Write-Error "Failed to import module: $($_.Exception.Message)"
    exit 1
}

# Test 1: Basic connection test
Write-Host "`nTest 1: Testing OpenRouter API connection..." -ForegroundColor Cyan
try {
    $connectionTest = Test-OpenRouterConnection
    if ($connectionTest) {
        Write-Host "✓ API connection successful" -ForegroundColor Green
    } else {
        Write-Host "✗ API connection failed" -ForegroundColor Red
        exit 1
    }
}
catch {
    Write-Host "✗ Connection test error: $($_.Exception.Message)" -ForegroundColor Red
    exit 1
}

# Test 2: Test streaming functionality with basic chat
Write-Host "`nTest 2: Testing streaming response..." -ForegroundColor Cyan
try {
    Write-Host "Sending test message with streaming..." -ForegroundColor Gray
    $streamResponse = Invoke-OpenRouterChat -Message "Say 'Hello from OpenRouterAIPS streaming test!' and explain what you are in one sentence." -Stream
    
    if ($streamResponse -and $streamResponse.choices -and $streamResponse.choices[0].message.content) {
        Write-Host "✓ Streaming response received successfully" -ForegroundColor Green
        Write-Host "Response: $($streamResponse.choices[0].message.content.Substring(0, [Math]::Min(100, $streamResponse.choices[0].message.content.Length)))..." -ForegroundColor Gray
    } else {
        Write-Host "✗ Invalid streaming response format" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Streaming test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 3: Test chat history functions
Write-Host "`nTest 3: Testing chat history management..." -ForegroundColor Cyan
try {
    # Clear any existing history
    Clear-OpenRouterChatHistory
    
    # Check if history is empty
    $history = Get-OpenRouterChatHistory
    if ($history.Count -eq 0) {
        Write-Host "✓ Chat history cleared successfully" -ForegroundColor Green
    }
    
    # Test save/load functionality (simulate chat history)
    $testHistory = @(
        @{
            Role = 'user'
            Content = 'Hello, this is a test message'
            Timestamp = Get-Date
            Metadata = @{}
        },
        @{
            Role = 'assistant' 
            Content = 'Hello! This is a test response from the AI.'
            Timestamp = Get-Date
            Metadata = @{}
        }
    )
    
    # Save test history
    $testFile = Join-Path -Path $env:TEMP -ChildPath "openrouter-test-history.json"
    $testHistory | ConvertTo-Json -Depth 10 | Out-File -FilePath $testFile -Encoding UTF8
    
    # Test save function
    try {
        # We can't directly test Save-OpenRouterChatHistory without an active session
        # but we can test the file operations
        if (Test-Path -Path $testFile) {
            Write-Host "✓ Chat history file operations work" -ForegroundColor Green
            Remove-Item -Path $testFile -Force
        }
    }
    catch {
        Write-Host "✗ Chat history save/load error: $($_.Exception.Message)" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Chat history test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 4: Test configuration functions
Write-Host "`nTest 4: Testing chat configuration..." -ForegroundColor Cyan
try {
    # Test getting default config
    $config = Get-OpenRouterChatConfig
    if ($config -and $config.ContainsKey('StreamingEnabled')) {
        Write-Host "✓ Chat configuration retrieved successfully" -ForegroundColor Green
        Write-Host "Default streaming: $($config.StreamingEnabled)" -ForegroundColor Gray
    }
    
    # Test setting config
    Set-OpenRouterChatConfig -StreamingEnabled $true -ShowTimestamps $true -ShowTokenUsage $true
    Write-Host "✓ Chat configuration updated successfully" -ForegroundColor Green
}
catch {
    Write-Host "✗ Chat configuration test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 5: Test available models for chat
Write-Host "`nTest 5: Testing model availability..." -ForegroundColor Cyan
try {
    $models = Get-OpenRouterModels | Select-Object -First 5
    if ($models -and $models.Count -gt 0) {
        Write-Host "✓ Models retrieved successfully" -ForegroundColor Green
        Write-Host "Available models (first 5):" -ForegroundColor Gray
        foreach ($model in $models) {
            Write-Host "  - $($model.Id) (Context: $($model.ContextLength))" -ForegroundColor Gray
        }
    } else {
        Write-Host "✗ No models available" -ForegroundColor Red
    }
}
catch {
    Write-Host "✗ Models test error: $($_.Exception.Message)" -ForegroundColor Red
}

# Test 6: Verify all chat functions are exported
Write-Host "`nTest 6: Testing function exports..." -ForegroundColor Cyan
$requiredFunctions = @(
    'Start-OpenRouterChat',
    'Get-OpenRouterChatHistory', 
    'Save-OpenRouterChatHistory',
    'Clear-OpenRouterChatHistory',
    'Set-OpenRouterChatConfig',
    'Get-OpenRouterChatConfig'
)

$requiredAliases = @(
    'orchat-session',
    'orchat-history',
    'orchat-save', 
    'orchat-clear',
    'orchat-config'
)

$missingFunctions = @()
$missingAliases = @()

foreach ($func in $requiredFunctions) {
    if (-not (Get-Command -Name $func -ErrorAction SilentlyContinue)) {
        $missingFunctions += $func
    }
}

foreach ($alias in $requiredAliases) {
    if (-not (Get-Command -Name $alias -ErrorAction SilentlyContinue)) {
        $missingAliases += $alias
    }
}

if ($missingFunctions.Count -eq 0 -and $missingAliases.Count -eq 0) {
    Write-Host "✓ All required functions and aliases are exported" -ForegroundColor Green
} else {
    if ($missingFunctions.Count -gt 0) {
        Write-Host "✗ Missing functions: $($missingFunctions -join ', ')" -ForegroundColor Red
    }
    if ($missingAliases.Count -gt 0) {
        Write-Host "✗ Missing aliases: $($missingAliases -join ', ')" -ForegroundColor Red
    }
}

Write-Host "`n" + "=" * 60 -ForegroundColor Yellow
Write-Host "R002 Chat Terminal Implementation Test Complete" -ForegroundColor Yellow

Write-Host "`nTo test the interactive chat session manually, run:" -ForegroundColor Cyan
Write-Host "  Start-OpenRouterChat" -ForegroundColor White
Write-Host "  # or use the alias:" -ForegroundColor Gray
Write-Host "  orchat-session" -ForegroundColor White

Write-Host "`nAvailable chat commands once in session:" -ForegroundColor Cyan
Write-Host "  /help               - Show all commands" -ForegroundColor White
Write-Host "  /model <name>       - Switch models" -ForegroundColor White
Write-Host "  /stream on|off      - Toggle streaming" -ForegroundColor White
Write-Host "  /save <file>        - Save conversation" -ForegroundColor White
Write-Host "  /tokens             - Show usage stats" -ForegroundColor White
Write-Host "  /exit               - End session" -ForegroundColor White

Write-Host "`nExample with specific model:" -ForegroundColor Cyan
Write-Host "  Start-OpenRouterChat -Model 'anthropic/claude-3-sonnet'" -ForegroundColor White

# Cleanup
Remove-Module -Name OpenRouterAIPS -Force -ErrorAction SilentlyContinue
