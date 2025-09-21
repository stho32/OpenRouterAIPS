#Requires -Version 5.1

<#
.SYNOPSIS
    Utility to fix German umlauts in AI responses
    
.DESCRIPTION
    Helper function to manually fix encoding issues with German umlauts
#>

function Fix-GermanText {
    param([string]$Text)
    
    if (-not $Text) { return $Text }
    
    $fixed = $Text
    $fixed = $fixed -replace 'mÃ¶', 'mö'     # möchten
    $fixed = $fixed -replace 'schÃ¶', 'schö' # schön  
    $fixed = $fixed -replace 'BÃ¼', 'Bü'     # Bücher
    $fixed = $fixed -replace 'sÃ¼', 'sü'     # süß
    $fixed = $fixed -replace 'Ã¤', 'ä'       # ä
    $fixed = $fixed -replace 'Ã¶', 'ö'       # ö
    $fixed = $fixed -replace 'Ã¼', 'ü'       # ü
    $fixed = $fixed -replace 'ÃŸ', 'ß'       # ß
    $fixed = $fixed -replace 'Ã„', 'Ä'       # Ä
    $fixed = $fixed -replace 'Ã–', 'Ö'       # Ö
    $fixed = $fixed -replace 'Ãœ', 'Ü'       # Ü
    $fixed = $fixed -replace 'Ã©', 'é'       # é
    $fixed = $fixed -replace 'Ã¨', 'è'       # è
    $fixed = $fixed -replace 'Ã ', 'à'       # à
    $fixed = $fixed -replace 'Ã([aeiou])', 'Ä$1'  # Remaining Ã + vowel
    
    return $fixed
}

# Import OpenRouterAIPS
Import-Module "$PSScriptRoot\..\Source\OpenRouterAIPS.psm1" -Force

# Test the encoding fix
Write-Host "Testing German text encoding fix..." -ForegroundColor Cyan
Write-Host

# Get a response with German text
$response = orchat "Antworten Sie auf Deutsch: 'Schöne Grüße aus München! Wir möchten gerne Kaffee trinken.'" -MaxTokens 50

Write-Host "Original AI Response:" -ForegroundColor Yellow
Write-Host $response.Content -ForegroundColor White

Write-Host
Write-Host "Fixed German Text:" -ForegroundColor Green
$fixedContent = Fix-GermanText -Text $response.Content
Write-Host $fixedContent -ForegroundColor White

Write-Host
Write-Host "Manual Fix Function Created!" -ForegroundColor Cyan
Write-Host "Usage: Fix-GermanText -Text 'your text with encoding issues'" -ForegroundColor Gray