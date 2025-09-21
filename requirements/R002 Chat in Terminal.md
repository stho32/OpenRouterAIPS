## R002 Chat in Terminal

Like other AIs where users can have a chat with an AI in the browser, we want to implement the same in the terminal so that the user can see the answer coming from the ai in the terminal as a stream and have a chat history for the conversation.

### Detailed Requirements

#### R002.1 Interactive Chat Session
- **Function**: `Start-OpenRouterChat` (alias: `orchat-session`)
- **Purpose**: Launch an interactive chat session that runs until the user exits
- **Behavior**:
  - Display a prompt for user input (e.g., "You: ")
  - Accept multi-line input with continuation prompts
  - Support commands like `/exit`, `/clear`, `/help`, `/model <model-name>`
  - Maintain conversation context across multiple exchanges

#### R002.2 Streaming Response Display
- **Function**: Extend `Invoke-OpenRouterChat` with `-Stream` parameter
- **Purpose**: Display AI responses as they are received from the API
- **Behavior**:
  - Show typing indicator while waiting for response
  - Display response text character by character or in chunks
  - Use appropriate colors/formatting to distinguish AI responses
  - Handle streaming errors gracefully

#### R002.3 Chat History Management
- **Functions**:
  - `Get-OpenRouterChatHistory` - Retrieve conversation history
  - `Save-OpenRouterChatHistory` - Export chat to file
  - `Clear-OpenRouterChatHistory` - Reset current session
- **Purpose**: Manage conversation context and persistence
- **Behavior**:
  - Store conversation in session memory during active chat
  - Support saving to JSON/text formats
  - Allow loading previous conversations
  - Implement conversation memory limits (configurable)

#### R002.4 User Interface Enhancements
- **Visual Elements**:
  - Color-coded messages (user vs AI)
  - Timestamp display (optional)
  - Token usage tracking and display
  - Model name indicator
  - Message numbering or indexing
- **Navigation**:
  - Support for scrolling through long conversations
  - Clear visual separation between messages
  - Status indicators (typing, processing, error states)

#### R002.5 Session Commands
- **Command System**: In-chat commands starting with `/`
- **Required Commands**:
  - `/exit` or `/quit` - End the chat session
  - `/clear` - Clear conversation history
  - `/help` - Show available commands
  - `/model <name>` - Switch AI model mid-conversation
  - `/save <filename>` - Save current conversation
  - `/load <filename>` - Load previous conversation
  - `/tokens` - Show token usage statistics
  - `/config` - Display current configuration
  - `/models` - List available models with pricing info
  - `/cost` - Show session cost and usage statistics
  - `/stats` - Display generation statistics from /generation endpoint

#### R002.6 Configuration Integration
- **Settings**: Extend existing configuration system
- **New Options**:
  - Default streaming behavior (on/off)
  - Chat display colors and formatting
  - Maximum conversation history length
  - Auto-save functionality
  - Prompt customization
  - Rate limit retry attempts and delay
  - Cost tracking and budget warnings
  - Default model selection for chat sessions

#### R002.7 Error Handling and Resilience
- **Network Issues**: Handle API timeouts and connection problems
- **Rate Limiting**: Implement backoff strategies for rate limits
- **Large Responses**: Handle responses that exceed terminal display limits
- **Input Validation**: Sanitize user input for security

#### R002.8 Advanced Features (Based on API Capabilities)
- **Cost Monitoring**: Real-time cost tracking using pricing data from models endpoint
- **Generation Analytics**: Access to generation statistics via /generation endpoint
- **Model Comparison**: Display model capabilities, context length, and pricing
- **Session Statistics**: Track total tokens, costs, and model usage per session
- **Budget Controls**: Optional spending limits and warnings
- **Performance Metrics**: Response time tracking and model performance comparison

### Technical Implementation Notes

#### API Endpoints Required
Based on OpenRouter API documentation, the following endpoints will be used:
- **POST /chat/completions** - Core chat functionality with streaming support
- **GET /models** - Model selection and validation
- **GET /generation** - Token usage tracking and cost monitoring

#### Streaming Implementation
- **API Support**: OpenRouter supports streaming via `"stream": true` parameter
- **Format**: Server-Sent Events (SSE) with `data:` prefix and `[DONE]` terminator
- **Response Structure**: `chat.completion.chunk` objects with `delta` content
- **PowerShell Handling**: Use `Invoke-WebRequest` with `-UseBasicParsing` for SSE parsing
- **Implementation**:
  ```powershell
  # Enable streaming in request body
  $body.stream = $true

  # Parse SSE data lines
  foreach ($line in $response.Content -split "`n") {
      if ($line.StartsWith("data: ") -and $line -ne "data: [DONE]") {
          $json = $line.Substring(6) | ConvertFrom-Json
          Write-Host $json.choices[0].delta.content -NoNewline
      }
  }
  ```

#### Model Management
- **Available Models**: Use GET /models endpoint to populate `/model` command options
- **Model Validation**: Verify model exists before switching
- **Popular Models**: Pre-configure common models (GPT-4, Claude-3, Llama-2, etc.)
- **Context Length**: Respect model-specific context limits from API response

#### Token Usage Tracking
- **Real-time Tracking**: Extract usage data from completion responses
- **Session Totals**: Accumulate prompt_tokens, completion_tokens, total_tokens
- **Cost Calculation**: Use pricing data from models endpoint
- **Display Format**: Show current message and session totals

#### Rate Limit Handling
- **Headers Monitoring**: Track X-RateLimit-* headers from responses
- **Backoff Strategy**: Implement exponential backoff on 429 responses
- **User Feedback**: Display rate limit status and retry timing
- **Error Recovery**: Graceful handling without session termination

#### Memory Management
- **Context Window**: Implement sliding window based on model context_length
- **Message Pruning**: Remove oldest messages when approaching limits
- **System Message Preservation**: Always maintain system prompt
- **User Notifications**: Warn when conversation is truncated

#### PowerShell-Specific Considerations
- **HTTP Requests**: Use Invoke-RestMethod for JSON APIs, Invoke-WebRequest for streaming
- **UTF-8 Encoding**: Handle international characters in responses
- **Console Colors**: Use Write-Host with -ForegroundColor for message distinction
- **Background Jobs**: Consider Start-Job for non-blocking streaming
- **Error Handling**: Wrap API calls in try-catch with meaningful error messages

#### Security Implementation
- **API Key Validation**: Verify OPENROUTER_API_KEY exists before starting session
- **Input Sanitization**: Validate user input for injection attempts
- **File Operations**: Secure handling of save/load operations with path validation
- **Error Information**: Avoid exposing sensitive API details in error messages

### Acceptance Criteria

1. User can start an interactive chat session with a simple command
2. AI responses stream in real-time to the terminal
3. Conversation history persists throughout the session
4. Users can switch models, save conversations, and use help commands
5. Visual formatting clearly distinguishes user and AI messages
6. Session handles errors gracefully without crashing
7. Chat functionality integrates seamlessly with existing module functions
8. Real-time cost tracking and budget controls work accurately
9. Model switching and comparison features function correctly
10. Session analytics and statistics are properly captured and displayed

## API Compatibility Analysis

### Fully Supported Features ✅
All requirements in this specification are **fully implementable** using the OpenRouter API:

1. **Streaming Chat**: Supported via `"stream": true` parameter with SSE format
2. **Model Management**: GET /models endpoint provides complete model list with metadata
3. **Token Tracking**: Usage data included in all completion responses
4. **Cost Calculation**: Pricing information available in models endpoint
5. **Rate Limit Handling**: Standard HTTP rate limit headers provided
6. **Error Handling**: Comprehensive error response format with codes and messages
7. **Generation Analytics**: GET /generation endpoint for usage statistics

### Required API Calls Summary
- **POST /chat/completions**: Core functionality, streaming, token usage
- **GET /models**: Model selection, validation, pricing, context limits
- **GET /generation**: Historical usage statistics and cost tracking

### No Additional APIs Needed
The current OpenRouter API provides all necessary endpoints and features to implement the complete chat terminal functionality as specified. No external services or additional APIs are required.

## Module Architecture Requirements

### Separate File Implementation
The chat terminal functionality should be implemented as a **separate PowerShell file** rather than being added to the main `Source/OpenRouterAIPS.psm1` file:

- **File Location**: `Source/OpenRouterAIPS.Chat.psm1` (or similar naming)
- **Loading Mechanism**: The chat functionality should be accessible through the main module but implemented separately
- **Integration**: The main `OpenRouterAIPS.psm1` should be able to load and expose the chat functions

### Modular Design Benefits
1. **Separation of Concerns**: Keep core API functions separate from interactive chat features
2. **Optional Loading**: Users can choose whether to load chat functionality
3. **Maintainability**: Easier to maintain and update chat features independently
4. **Code Organization**: Cleaner separation between basic API calls and advanced UI features

### Integration Approach
The main module (`Source/OpenRouterAIPS.psm1`) should:
- **Import the chat module** when needed
- **Export chat functions** alongside existing functions
- **Maintain unified aliases** (e.g., `orchat-session` for `Start-OpenRouterChat`)
- **Provide seamless user experience** - users shouldn't need to know about the separate file

### Suggested File Structure
```
Source/
├── OpenRouterAIPS.psm1          # Main module (existing functions)
├── OpenRouterAIPS.Chat.psm1     # Chat terminal functionality (new)
└── OpenRouterAIPS.psd1          # Module manifest (updated exports)
```

This architecture ensures the chat functionality extends the existing module without bloating the core API implementation.