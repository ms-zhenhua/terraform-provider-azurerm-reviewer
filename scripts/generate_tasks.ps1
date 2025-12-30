param(
    [Parameter(Mandatory = $true)]
    [string]$TargetDir
)

$ErrorActionPreference = "Stop"

$scriptPath = $MyInvocation.MyCommand.Definition
$scriptDir = Split-Path -Parent $scriptPath
$workspaceRoot = Split-Path -Parent $scriptDir

$tasksDir = Join-Path $TargetDir "tasks"
$srcDir = Join-Path $TargetDir "src"

if (-not (Test-Path $srcDir)) {
    Write-Error "Source directory not found at $srcDir. Please run prepare_code.ps1 first."
    exit 1
}

try {
    if (Test-Path $tasksDir) {
        Write-Host "Tasks already generated in $tasksDir"
        return
    }
    New-Item -ItemType Directory -Path $tasksDir | Out-Null

    function Generate-TaskPair {
        param (
            $RuleFile,
            $TargetFile,
            $RuleRoot,
            $TargetRoot,
            $TasksDir
        )
        $uuid = [guid]::NewGuid().ToString()
        $taskFileName = "$uuid.txt"
        $taskFilePath = Join-Path $TasksDir $taskFileName

        # Get relative paths
        $relativeRulePath = $RuleFile.FullName.Substring($RuleRoot.Length + 1).Replace('\', '/')
        $relativeTargetFilePath = $TargetFile.FullName.Substring($TargetRoot.Length + 1).Replace('\', '/')
        
        # JSON file path (strip src/ if present to match example)
        $jsonFilePath = $relativeTargetFilePath
        if ($jsonFilePath.StartsWith("src/")) {
            $jsonFilePath = $jsonFilePath.Substring(4)
        }

        $content = @"
You are an expert of AzureRM Provider.
Analyze '$relativeTargetFilePath' for violations of the rule in '$relativeRulePath'.
Output the results to 'task_results/$uuid.txt' in the following JSON format.

[
    {
        "rule": "$relativeRulePath",
        "file": "$jsonFilePath",
        "line": <line_number>,
        "message": "<violation_reason_and_fix>"
    }
]

Requirements:
1. The 'message' field must explain the violation and provide a solution.
2. The 'line' number must be accurate based on the content of '$relativeTargetFilePath'.
"@
        
        Set-Content -Path $taskFilePath -Value $content -Encoding UTF8
    }

    function Process-RuleConfig {
        param (
            $RuleSubPath,
            $TargetSubPaths,
            $FileIncludes
        )
        
        $fullRulePath = Join-Path $workspaceRoot $RuleSubPath
        if (-not (Test-Path $fullRulePath)) { return }
        
        $rules = Get-ChildItem -Path $fullRulePath -Filter "*.md" -File
        
        $files = @()
        foreach ($subPath in $TargetSubPaths) {
            $fullTargetPath = Join-Path $TargetDir $subPath
            if (Test-Path $fullTargetPath) {
                $files += Get-ChildItem -Path $fullTargetPath -Recurse -Include $FileIncludes -File
            }
        }
        
        if ($files.Count -gt 0) {
            Write-Host "Processing $($rules.Count) rules in $RuleSubPath against $($files.Count) files."
            foreach ($rule in $rules) {
                foreach ($file in $files) {
                    Generate-TaskPair -RuleFile $rule -TargetFile $file -RuleRoot $workspaceRoot -TargetRoot $TargetDir -TasksDir $tasksDir
                }
            }
        }
    }

    # 1. go -> src/internal/*.go
    Process-RuleConfig -RuleSubPath "rules\go" -TargetSubPaths @("src\internal") -FileIncludes "*.go"

    # 2. go_common -> src/internal/*_resource.go, *_data_source.go
    Process-RuleConfig -RuleSubPath "rules\go_common" -TargetSubPaths @("src\internal") -FileIncludes @("*_resource.go", "*_data_source.go")

    # 3. go_resource -> src/internal/*_resource.go
    Process-RuleConfig -RuleSubPath "rules\go_resource" -TargetSubPaths @("src\internal") -FileIncludes "*_resource.go"

    # 4. go_data_source -> src/internal/*_data_source.go
    Process-RuleConfig -RuleSubPath "rules\go_data_source" -TargetSubPaths @("src\internal") -FileIncludes "*_data_source.go"

    # 5. test_common -> src/internal/*_data_source_test.go, *_resource_test.go
    Process-RuleConfig -RuleSubPath "rules\test_common" -TargetSubPaths @("src\internal") -FileIncludes @("*_data_source_test.go", "*_resource_test.go")

    # 6. test_resource -> src/internal/*_resource_test.go
    Process-RuleConfig -RuleSubPath "rules\test_resource" -TargetSubPaths @("src\internal") -FileIncludes "*_resource_test.go"

    # 7. test_data_source -> src/internal/*_data_source_test.go
    Process-RuleConfig -RuleSubPath "rules\test_data_source" -TargetSubPaths @("src\internal") -FileIncludes "*_data_source_test.go"

    # 8. doc_common -> src/website/docs/r/*.html.markdown, src/website/docs/d/*.html.markdown
    Process-RuleConfig -RuleSubPath "rules\doc_common" -TargetSubPaths @("src\website\docs\r", "src\website\docs\d") -FileIncludes "*.html.markdown"

    # 9. doc_resource -> src/website/docs/r/*.html.markdown
    Process-RuleConfig -RuleSubPath "rules\doc_resource" -TargetSubPaths @("src\website\docs\r") -FileIncludes "*.html.markdown"

    # 10. doc_data_source -> src/website/docs/d/*.html.markdown
    Process-RuleConfig -RuleSubPath "rules\doc_data_source" -TargetSubPaths @("src\website\docs\d") -FileIncludes "*.html.markdown"

    # 11. Multi-file Validations
    & "$scriptDir\generate_multi_file_tasks.ps1" -RuleRoot $workspaceRoot -TargetDir $TargetDir -TasksDir $tasksDir

}
catch {
    Write-Error "An error occurred: $_"
    if (Test-Path $tasksDir) { Remove-Item -Path $tasksDir -Recurse -Force }
    exit 1
}
