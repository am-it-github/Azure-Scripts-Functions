$sourceTemplateFile = "path\to\source\template\file.json"
$outputBicepFile = "path\to\output\bicep\file.bicep"

# Convert the ARM template to a BICEP file
ConvertTo-Bicep -InputPath $sourceTemplateFile -OutputPath $outputBicepFile -Verbose

# Check for any conversion errors
if ($LastExitCode -ne 0) {
    Write-Output "There were errors during the conversion process. Please check the output above for more information."
} else {
    Write-Output "Conversion was successful! The BICEP file was saved to $outputBicepFile."
}
