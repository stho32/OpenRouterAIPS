# Example usage of OpenRouterAIPS Chat Terminal functionality
# This demonstrates all the features implemented for R002

# Import the module
Import-Module -Name "$PSScriptRoot\..\Source\OpenRouterAIPS.psm1" -Force

Write-Host "OpenRouterAIPS Chat Terminal - Usage Examples" -ForegroundColor Yellow
Write-Host "=" * 50 -ForegroundColor Yellow

# Example 1: Basic chat session
Write-Host "`nExample 1: Starting a basic chat session" -ForegroundColor Cyan
Write-Host "Command: Start-OpenRouterChat" -ForegroundColor Gray
Write-Host "Alias:   orchat-session" -ForegroundColor Gray
Write-Host ""
Write-Host "This will start an interactive chat session with these features:" -ForegroundColor White
Write-Host "• Streaming responses (real-time text display)" -ForegroundColor Green  
Write-Host "• Conversation history management" -ForegroundColor Green
Write-Host "• Token usage tracking" -ForegroundColor Green
Write-Host "• Cost monitoring" -ForegroundColor Green
Write-Host "• Model switching during conversation" -ForegroundColor Green
Write-Host "• Session commands (type /help in session)" -ForegroundColor Green

# Example 2: Starting with specific configuration
Write-Host "`nExample 2: Chat session with specific model and settings" -ForegroundColor Cyan
Write-Host "Start-OpenRouterChat -Model 'anthropic/claude-3-sonnet' -SystemPrompt 'You are a helpful coding assistant' -MaxTokens 2000" -ForegroundColor Gray
Write-Host ""
Write-Host "This starts a session with:" -ForegroundColor White
Write-Host "• Claude 3 Sonnet model" -ForegroundColor Green
Write-Host "• Custom system prompt for coding assistance" -ForegroundColor Green  
Write-Host "• Higher token limit (2000 instead of default 1000)" -ForegroundColor Green

# Example 3: Session commands
Write-Host "`nExample 3: Available commands during chat session" -ForegroundColor Cyan
Write-Host "Once in a chat session, you can use these commands:" -ForegroundColor White
Write-Host ""

$commands = @(
    @{ Command = "/help"; Description = "Show all available commands" },
    @{ Command = "/exit or /quit"; Description = "End the chat session" },
    @{ Command = "/clear"; Description = "Clear conversation history" },
    @{ Command = "/model <name>"; Description = "Switch to a different AI model" },
    @{ Command = "/models"; Description = "List available models with details" },
    @{ Command = "/save <filename>"; Description = "Save conversation to file" },
    @{ Command = "/load <filename>"; Description = "Load previous conversation" },
    @{ Command = "/tokens"; Description = "Show token usage statistics" },
    @{ Command = "/cost"; Description = "Show session cost information" },
    @{ Command = "/stats"; Description = "Show detailed session statistics" },
    @{ Command = "/config"; Description = "Display current configuration" },
    @{ Command = "/stream on|off"; Description = "Toggle streaming responses" },
    @{ Command = "/system <prompt>"; Description = "Set or update system prompt" }
)

foreach ($cmd in $commands) {
    Write-Host "  $($cmd.Command.PadRight(20)) - $($cmd.Description)" -ForegroundColor Gray
}

# Example 4: Configuration management
Write-Host "`nExample 4: Managing chat configuration" -ForegroundColor Cyan
Write-Host "# View current configuration" -ForegroundColor Gray
Write-Host "Get-OpenRouterChatConfig" -ForegroundColor White
Write-Host ""
Write-Host "# Update configuration settings" -ForegroundColor Gray
Write-Host "Set-OpenRouterChatConfig -StreamingEnabled `$true -ShowTimestamps `$true -BudgetLimit 5.00" -ForegroundColor White
Write-Host ""
Write-Host "Configuration options include:" -ForegroundColor White
Write-Host "• StreamingEnabled - Enable/disable real-time response streaming" -ForegroundColor Green
Write-Host "• ShowTimestamps - Display timestamps with messages" -ForegroundColor Green
Write-Host "• ShowTokenUsage - Show token count after each response" -ForegroundColor Green
Write-Host "• ShowCost - Display cost information" -ForegroundColor Green
Write-Host "• MaxHistoryLength - Maximum messages to keep in memory" -ForegroundColor Green
Write-Host "• AutoSave - Automatically save sessions when ending" -ForegroundColor Green
Write-Host "• BudgetLimit - Set spending limit with warnings" -ForegroundColor Green

# Example 5: History management
Write-Host "`nExample 5: Managing conversation history" -ForegroundColor Cyan
Write-Host "# View conversation history" -ForegroundColor Gray
Write-Host "Get-OpenRouterChatHistory" -ForegroundColor White
Write-Host ""
Write-Host "# Get history in different formats" -ForegroundColor Gray
Write-Host "Get-OpenRouterChatHistory -Format Text" -ForegroundColor White
Write-Host "Get-OpenRouterChatHistory -Format JSON" -ForegroundColor White
Write-Host ""
Write-Host "# Save conversation to file" -ForegroundColor Gray
Write-Host "Save-OpenRouterChatHistory -FilePath 'my-conversation.json'" -ForegroundColor White
Write-Host "Save-OpenRouterChatHistory -FilePath 'my-conversation.txt' -Format Text" -ForegroundColor White
Write-Host ""
Write-Host "# Clear current session history" -ForegroundColor Gray
Write-Host "Clear-OpenRouterChatHistory" -ForegroundColor White

# Example 6: Non-streaming usage
Write-Host "`nExample 6: Using enhanced Invoke-OpenRouterChat with streaming" -ForegroundColor Cyan
Write-Host "# Regular response (non-streaming)" -ForegroundColor Gray
Write-Host "`$response = Invoke-OpenRouterChat -Message 'Hello, how are you?'" -ForegroundColor White
Write-Host ""
Write-Host "# Streaming response (real-time display)" -ForegroundColor Gray
Write-Host "`$response = Invoke-OpenRouterChat -Message 'Explain quantum computing' -Stream" -ForegroundColor White
Write-Host ""
Write-Host "# Streaming with specific model" -ForegroundColor Gray
Write-Host "`$response = Invoke-OpenRouterChat -Message 'Write a Python function' -Model 'anthropic/claude-3-sonnet' -Stream" -ForegroundColor White

# Example 7: Aliases for convenience
Write-Host "`nExample 7: Convenient aliases" -ForegroundColor Cyan
Write-Host "All functions have short aliases for quick access:" -ForegroundColor White
Write-Host ""

$aliases = @(
    @{ Alias = "orchat-session"; Function = "Start-OpenRouterChat" },
    @{ Alias = "orchat-history"; Function = "Get-OpenRouterChatHistory" },
    @{ Alias = "orchat-save"; Function = "Save-OpenRouterChatHistory" },
    @{ Alias = "orchat-clear"; Function = "Clear-OpenRouterChatHistory" },
    @{ Alias = "orchat-config"; Function = "Set-OpenRouterChatConfig" },
    @{ Alias = "orchat"; Function = "Invoke-OpenRouterChat" },
    @{ Alias = "ormodels"; Function = "Get-OpenRouterModels" }
)

foreach ($alias in $aliases) {
    Write-Host "  $($alias.Alias.PadRight(20)) → $($alias.Function)" -ForegroundColor Gray
}

# Example 8: Workflow example
Write-Host "`nExample 8: Complete workflow example" -ForegroundColor Cyan
Write-Host @"
# 1. Configure your session preferences
Set-OpenRouterChatConfig -StreamingEnabled `$true -ShowCost `$true -BudgetLimit 10.00

# 2. Start a chat session with a coding assistant setup
orchat-session -Model 'anthropic/claude-3-sonnet' -SystemPrompt 'You are an expert PowerShell developer'

# 3. During the session, use commands like:
#    /model openai/gpt-4      # Switch to GPT-4
#    /save my-coding-session.json  # Save your conversation
#    /tokens                  # Check token usage
#    /cost                    # Check spending
#    /exit                    # End session

# 4. Later, review your conversation
orchat-history -Format Text

# 5. Or load a previous conversation
# (In new session) /load my-coding-session.json
"@ -ForegroundColor White

Write-Host "`n" + "=" * 50 -ForegroundColor Yellow
Write-Host "Ready to start your first chat session!" -ForegroundColor Yellow
Write-Host "Run: orchat-session" -ForegroundColor Cyan

# Clean up
Remove-Module -Name OpenRouterAIPS -Force -ErrorAction SilentlyContinue
