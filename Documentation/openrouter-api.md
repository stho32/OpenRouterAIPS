# OpenRouter API Documentation

## Overview

OpenRouter provides a unified interface to access multiple AI models through a single API. It's compatible with the OpenAI API format, making it easy to switch between different AI providers.

## Base URL

```
https://openrouter.ai/api/v1
```

## Authentication

All API requests require authentication using an API key. Set your API key in the request headers:

```
Authorization: Bearer YOUR_API_KEY
```

### Environment Variable
For this PowerShell project, the API key should be stored in the `OPENROUTER_API_KEY` environment variable.

```powershell
$env:OPENROUTER_API_KEY
```

## Core Endpoints

### 1. Chat Completions
**Endpoint:** `POST /chat/completions`

The main endpoint for generating text completions using various AI models.

#### Request Headers
```
Content-Type: application/json
Authorization: Bearer YOUR_API_KEY
HTTP-Referer: YOUR_SITE_URL (optional, for rankings)
X-Title: YOUR_SITE_NAME (optional, for rankings)
```

#### Request Body
```json
{
  "model": "model-identifier",
  "messages": [
    {
      "role": "system|user|assistant",
      "content": "message content"
    }
  ],
  "max_tokens": 4096,
  "temperature": 0.7,
  "top_p": 1,
  "frequency_penalty": 0,
  "presence_penalty": 0,
  "stream": false
}
```

#### Required Parameters
- `model`: The AI model to use (e.g., "openai/gpt-3.5-turbo", "anthropic/claude-3-sonnet")
- `messages`: Array of message objects with role and content

#### Optional Parameters
- `max_tokens`: Maximum tokens to generate (default varies by model)
- `temperature`: Randomness in output (0.0 to 2.0, default 0.7)
- `top_p`: Nucleus sampling parameter (0.0 to 1.0, default 1.0)
- `frequency_penalty`: Penalty for repeated tokens (-2.0 to 2.0, default 0.0)
- `presence_penalty`: Penalty for new tokens (-2.0 to 2.0, default 0.0)
- `stream`: Enable streaming responses (boolean, default false)

#### Response
```json
{
  "id": "chatcmpl-abc123",
  "object": "chat.completion",
  "created": 1677652288,
  "model": "openai/gpt-3.5-turbo",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "Generated response text"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 10,
    "completion_tokens": 20,
    "total_tokens": 30
  }
}
```

### 2. Models List
**Endpoint:** `GET /models`

Retrieve a list of available models.

#### Request Headers
```
Authorization: Bearer YOUR_API_KEY
```

#### Response
```json
{
  "object": "list",
  "data": [
    {
      "id": "openai/gpt-3.5-turbo",
      "object": "model",
      "created": 1677610602,
      "owned_by": "openai",
      "context_length": 4096,
      "pricing": {
        "prompt": "0.0015",
        "completion": "0.002"
      }
    }
  ]
}
```

### 3. Generation Stats
**Endpoint:** `GET /generation`

Get generation statistics for your account.

#### Request Headers
```
Authorization: Bearer YOUR_API_KEY
```

#### Response
```json
{
  "object": "generation",
  "data": [
    {
      "id": "gen_abc123",
      "model": "openai/gpt-3.5-turbo",
      "created_at": "2023-03-01T12:00:00Z",
      "tokens": 150
    }
  ],
  "total_cost": 0.25
}
```

## Popular Models

### OpenAI Models
- `openai/gpt-4` - GPT-4 (latest)
- `openai/gpt-4-turbo` - GPT-4 Turbo
- `openai/gpt-3.5-turbo` - GPT-3.5 Turbo

### Anthropic Models
- `anthropic/claude-3-opus` - Claude 3 Opus
- `anthropic/claude-3-sonnet` - Claude 3 Sonnet
- `anthropic/claude-3-haiku` - Claude 3 Haiku

### Other Popular Models
- `meta-llama/llama-2-70b-chat` - Llama 2 70B
- `google/gemini-pro` - Gemini Pro
- `mistralai/mixtral-8x7b-instruct` - Mixtral 8x7B

## Error Handling

### Common HTTP Status Codes
- `200` - Success
- `400` - Bad Request (invalid parameters)
- `401` - Unauthorized (invalid API key)
- `429` - Too Many Requests (rate limit exceeded)
- `500` - Internal Server Error
- `502` - Bad Gateway (model provider error)

### Error Response Format
```json
{
  "error": {
    "message": "Error description",
    "type": "invalid_request_error",
    "code": "invalid_api_key"
  }
}
```

## Rate Limits

- Rate limits vary by model and usage tier
- Monitor the following response headers:
  - `X-RateLimit-Limit`
  - `X-RateLimit-Remaining`
  - `X-RateLimit-Reset`

## Streaming Responses

Enable streaming by setting `"stream": true` in the request body. Streaming responses use Server-Sent Events (SSE) format.

### Streaming Response Format
```
data: {"id":"chatcmpl-abc123","object":"chat.completion.chunk","created":1677652288,"model":"openai/gpt-3.5-turbo","choices":[{"index":0,"delta":{"content":"Hello"},"finish_reason":null}]}

data: {"id":"chatcmpl-abc123","object":"chat.completion.chunk","created":1677652288,"model":"openai/gpt-3.5-turbo","choices":[{"index":0,"delta":{},"finish_reason":"stop"}]}

data: [DONE]
```

## PowerShell Integration Notes

### Making HTTP Requests
Use `Invoke-RestMethod` or `Invoke-WebRequest` for API calls.

### Example Request
```powershell
$headers = @{
    "Authorization" = "Bearer $env:OPENROUTER_API_KEY"
    "Content-Type" = "application/json"
}

$body = @{
    model = "openai/gpt-3.5-turbo"
    messages = @(
        @{
            role = "user"
            content = "Hello, world!"
        }
    )
    max_tokens = 100
} | ConvertTo-Json -Depth 3

$response = Invoke-RestMethod -Uri "https://openrouter.ai/api/v1/chat/completions" -Method Post -Headers $headers -Body $body
```

## Best Practices

1. **Error Handling**: Always implement proper error handling for API failures
2. **Rate Limiting**: Respect rate limits and implement backoff strategies
3. **Model Selection**: Choose appropriate models based on cost and performance needs
4. **Token Management**: Monitor token usage to control costs
5. **Streaming**: Use streaming for better user experience with long responses

## Security Notes

- Never hardcode API keys in source code
- Use environment variables for API key storage
- Implement proper access controls for production deployments
- Monitor API usage and costs regularly

---

*Documentation generated for OpenRouterAIPS PowerShell project*
*Last updated: 2025-09-20*