# OPENROUTERAIPS

OPENROUTERAIPS is a powershell script collection that interacts with OpenRouter API
to provide commandline tools for interacting with AI models.

## Core Requirements

### R001.1 API Integration
- Connect to OpenRouter API using secure authentication
- Support multiple AI models available through OpenRouter
- Handle API rate limiting and error responses gracefully

### R001.2 Command Line Interface
- Provide simple PowerShell cmdlets for AI interactions
- Support parameter-based input for prompts and model selection
- Enable pipeline input for batch processing

### R001.3 Configuration Management
- Retrieve API key from OPENROUTER_API_KEY environment variable
- Allow model preference configuration
- Support environment-specific settings

### R001.4 Output Handling
- Return structured PowerShell objects
- Support formatted text output for direct consumption
- Enable output redirection to files

### R001.5 Error Management
- Implement proper error handling for API failures
- Provide meaningful error messages
- Support verbose logging for troubleshooting

## Technical Constraints
- PowerShell 5.1+ compatibility
- No external dependencies beyond standard PowerShell modules
- Simple, direct code without special characters or icons
- Windows-focused implementation

