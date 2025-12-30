param (
    [string]$RuleRoot,
    [string]$TargetDir,
    [string]$TasksDir
)

function Generate-TaskMultiFile {
    param (
        $RuleFile,
        $TargetFiles,
        $RuleRoot,
        $TargetRoot,
        $TasksDir
    )
    $uuid = [guid]::NewGuid().ToString()
    $taskFileName = "$uuid.txt"
    $taskFilePath = Join-Path $TasksDir $taskFileName

    # Get relative paths
    $relativeRulePath = $RuleFile.FullName.Substring($RuleRoot.Length + 1).Replace('\', '/')
    
    $targetPaths = @()
    foreach ($file in $TargetFiles) {
        $targetPaths += $file.FullName.Substring($TargetRoot.Length + 1).Replace('\', '/')
    }
    $targetFilesStr = $targetPaths -join "', '"

    $content = @"
You are an expert of AzureRM Provider.
Analyze '$targetFilesStr' for violations of the rule in '$relativeRulePath'.
Output the results to 'task_results/$uuid.txt' in the following JSON format.

[
    {
        "rule": "$relativeRulePath",
        "file": "<relative_path_of_the_file_with_violation>",
        "line": <line_number>,
        "message": "<violation_reason_and_fix>"
    }
]

Requirements:
1. The 'message' field must explain the violation and provide a solution.
2. The 'line' number must be accurate based on the content of the file.
"@
    
    Set-Content -Path $taskFilePath -Value $content -Encoding UTF8
}

# Custom Enum Validation
$enumRulePath = Join-Path $RuleRoot "rules\custom\enum_validation.md"
if (Test-Path $enumRulePath) {
    $enumRule = Get-Item $enumRulePath
    $internalDir = Join-Path $TargetDir "src\internal"
    
    # Resources
    if (Test-Path $internalDir) {
        $resourceFiles = Get-ChildItem -Path $internalDir -Recurse -Filter "*_resource.go" -File
        foreach ($resFile in $resourceFiles) {
            $baseName = $resFile.Name -replace "_resource.go$", ""
            $docPath = Join-Path $TargetDir "src\website\docs\r\$baseName.html.markdown"
            
            if (Test-Path $docPath) {
                $docFile = Get-Item $docPath
                Generate-TaskMultiFile -RuleFile $enumRule -TargetFiles @($resFile, $docFile) -RuleRoot $RuleRoot -TargetRoot $TargetDir -TasksDir $TasksDir
            }
        }

        # Data Sources
        $dataSourceFiles = Get-ChildItem -Path $internalDir -Recurse -Filter "*_data_source.go" -File
        foreach ($dsFile in $dataSourceFiles) {
            $baseName = $dsFile.Name -replace "_data_source.go$", ""
            $docPath = Join-Path $TargetDir "src\website\docs\d\$baseName.html.markdown"
            
            if (Test-Path $docPath) {
                $docFile = Get-Item $docPath
                Generate-TaskMultiFile -RuleFile $enumRule -TargetFiles @($dsFile, $docFile) -RuleRoot $RuleRoot -TargetRoot $TargetDir -TasksDir $TasksDir
            }
        }
    }
}

# Avoid Explicit Key Exists Checks
$keyExistsRulePath = Join-Path $RuleRoot "rules\custom\avoid_explicit_key_exists_checks.md"
if (Test-Path $keyExistsRulePath) {
    $keyExistsRule = Get-Item $keyExistsRulePath
    $internalDir = Join-Path $TargetDir "src\internal"
    
    if (Test-Path $internalDir) {
        # Resources
        $resourceFiles = Get-ChildItem -Path $internalDir -Recurse -Filter "*_resource.go" -File
        foreach ($resFile in $resourceFiles) {
            $baseName = $resFile.Name -replace "_resource.go$", ""
            $testFileName = "${baseName}_resource_test.go"
            $testFilePath = Join-Path $resFile.DirectoryName $testFileName
            
            if (Test-Path $testFilePath) {
                $testFile = Get-Item $testFilePath
                Generate-TaskMultiFile -RuleFile $keyExistsRule -TargetFiles @($resFile, $testFile) -RuleRoot $RuleRoot -TargetRoot $TargetDir -TasksDir $TasksDir
            }
        }

        # Data Sources
        $dataSourceFiles = Get-ChildItem -Path $internalDir -Recurse -Filter "*_data_source.go" -File
        foreach ($dsFile in $dataSourceFiles) {
            $baseName = $dsFile.Name -replace "_data_source.go$", ""
            $testFileName = "${baseName}_data_source_test.go"
            $testFilePath = Join-Path $dsFile.DirectoryName $testFileName
            
            if (Test-Path $testFilePath) {
                $testFile = Get-Item $testFilePath
                Generate-TaskMultiFile -RuleFile $keyExistsRule -TargetFiles @($dsFile, $testFile) -RuleRoot $RuleRoot -TargetRoot $TargetDir -TasksDir $TasksDir
            }
        }
    }
}
