#Requires -Version 5.1

# Test encoding fix
$problematicText = "Wir mÃ¶chten schÃ¶ne BÃ¼cher lesen und sÃ¼ÃŸe Ãpfel essen."

Write-Host "Original: $problematicText" -ForegroundColor Red

# Individual fixes step by step
$step1 = $problematicText -replace 'Ã¶', 'ö'
Write-Host "Step 1 (ö): $step1" -ForegroundColor Yellow

$step2 = $step1 -replace 'Ã¼', 'ü'  
Write-Host "Step 2 (ü): $step2" -ForegroundColor Yellow

$step3 = $step2 -replace 'ÃŸ', 'ß'
Write-Host "Step 3 (ß): $step3" -ForegroundColor Yellow

$step4 = $step3 -replace 'Ã¤', 'ä'
Write-Host "Step 4 (ä): $step4" -ForegroundColor Yellow

# Check what's left
$remaining = $step4 -split '' | Where-Object { $_ -match '[Ã]' } | Sort-Object | Get-Unique
Write-Host "Remaining problematic characters: $($remaining -join ', ')" -ForegroundColor Magenta

# Try to identify the problem with "Ãpfel"
$apfelTest = "Ãpfel"
Write-Host "Ãpfel analysis:" -ForegroundColor Cyan
for ($i = 0; $i -lt $apfelTest.Length; $i++) {
    $char = $apfelTest[$i]
    Write-Host "  [$i]: '$char' (Unicode: $([int][char]$char))" -ForegroundColor Gray
}

# Final comprehensive fix
$final = $step4 -replace 'Ã([aeiouAEIOU])', 'Ä$1'  # Capital A-umlaut prefix
Write-Host "Final result: $final" -ForegroundColor Green