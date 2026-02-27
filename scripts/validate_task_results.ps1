<#
.SYNOPSIS
    Validates task results using copilot CLI to remove false positives.
.DESCRIPTION
    For each file under task_results/, uses copilot CLI to validate the found errors,
    removes false positives, and writes the final filtered results to validated_results/
    with the same file name. Files with no violations are copied directly.
.PARAMETER TargetDir
    The target directory containing task_results/ and tasks/ folders.
.PARAMETER Model
    Optional model to use with the copilot CLI.
.PARAMETER MaxParallel
    Maximum number of parallel validation tasks to run. Default is 3.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,

    [string]$Model,

    [int]$MaxParallel = 3
)

$ErrorActionPreference = "Stop"

$taskResultsDir = Join-Path $TargetDir "task_results"
$validatedResultsDir = Join-Path $TargetDir "validated_results"

# Ensure we are in the target directory for relative paths in copilot commands to work as expected
Push-Location $TargetDir

try {
    # Create validated_results folder if it doesn't exist
    if (-not (Test-Path $validatedResultsDir)) {
        New-Item -ItemType Directory -Path $validatedResultsDir -Force | Out-Null
        Write-Host "Created directory: $validatedResultsDir" -ForegroundColor Cyan
    }

    # Check that task_results directory exists
    if (-not (Test-Path $taskResultsDir)) {
        Write-Error "Task results directory not found at $taskResultsDir. Please run run_tasks.ps1 first."
        exit 1
    }

    $allResultFiles = Get-ChildItem -Path $taskResultsDir -Filter "*.txt" -File
    Write-Host "Found $($allResultFiles.Count) task result files." -ForegroundColor Cyan

    # Separate files with violations from empty result files
    $filesWithViolations = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
    $emptyFiles = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

    foreach ($file in $allResultFiles) {
        $content = Get-Content -Path $file.FullName -Raw
        $trimmed = if ($content) { $content.Trim() } else { "" }
        if ($trimmed -eq "" -or $trimmed -eq "[]") {
            $emptyFiles.Add($file)
        }
        else {
            $filesWithViolations.Add($file)
        }
    }

    Write-Host "Files with violations: $($filesWithViolations.Count), Empty files: $($emptyFiles.Count)" -ForegroundColor Cyan

    # Copy empty result files directly — no violations to validate
    foreach ($file in $emptyFiles) {
        $destPath = Join-Path $validatedResultsDir $file.Name
        if (-not (Test-Path $destPath)) {
            Copy-Item -Path $file.FullName -Destination $destPath
        }
    }

    # Shared state for error handling across parallel threads
    $syncHash = [hashtable]::Synchronized(@{
            HasError       = $false
            CompletedCount = 0
        })

    $totalTasks = $filesWithViolations.Count

    # Validate files with violations in parallel
    $filesWithViolations | ForEach-Object -Parallel {
        $file = $_
        $syncHash = $using:syncHash
        $validatedResultsDir = $using:validatedResultsDir
        $TargetDir = $using:TargetDir
        $Model = $using:Model
        $totalTasks = $using:totalTasks

        # Set location to target directory
        Set-Location $TargetDir

        # Clear NODE_OPTIONS to prevent VS Code debugger from attaching to parallel processes
        $env:NODE_OPTIONS = $null

        # Check if we should abort due to previous error
        if ($syncHash.HasError) { return }

        $validatedFilePath = Join-Path $validatedResultsDir $file.Name

        # Check if validated result already exists (resume support)
        if (Test-Path $validatedFilePath) {
            [System.Threading.Monitor]::Enter($syncHash.SyncRoot)
            try { $syncHash.CompletedCount++ } finally { [System.Threading.Monitor]::Exit($syncHash.SyncRoot) }
            Write-Host "Skipping $($file.Name) - Validated result already exists." -ForegroundColor Gray
            return
        }

        Write-Host "Validating $($file.Name)..." -ForegroundColor Green

        $resultContent = Get-Content -Path $file.FullName -Raw
        $relativeResultPath = "task_results/$($file.Name)"
        $relativeValidatedPath = "validated_results/$($file.Name)"

        $prompt = @"
You are an expert of AzureRM Provider.
Validate each violation in '$relativeResultPath' to determine whether it is a real violation or a false positive.

The reported violations to validate are:
$resultContent

For each violation:
1. Read the actual source file at the exact line number specified.
2. Read the rule definition to understand what constitutes a violation.
3. Confirm whether the violation is legitimate based on the actual code at that line.
4. Remove any false positives (e.g. the code is already correct or the rule does not apply in this context).

Output the validated results to '$relativeValidatedPath' using the same JSON format. If no violations remain after validation, write an empty array [].
"@

        $maxRetries = 3
        $retryCount = 0
        $success = $false

        while (-not $success) {
            try {
                # Run copilot validation
                if ($Model) {
                    $output = copilot -p $prompt --model $Model --allow-all-tools --allow-all-paths 2>&1
                }
                else {
                    $output = copilot -p $prompt --allow-all-tools --allow-all-paths 2>&1
                }
                $output | Out-String | Write-Host

                if ($LASTEXITCODE -ne 0) {
                    $outputString = $output | Out-String
                    # Handle known libuv assertion failure on Windows which happens on exit
                    if ($outputString -match "Assertion failed: !\(handle->flags & UV_HANDLE_CLOSING\)") {
                        Write-Host "Validation of $($file.Name) encountered a known shutdown error (libuv assertion), but likely completed." -ForegroundColor Yellow
                        if (Test-Path $validatedFilePath) {
                            Write-Host "Validated result file created successfully. Ignoring exit code." -ForegroundColor Green
                        }
                        else {
                            throw "Copilot exited with code $LASTEXITCODE and validated result file is missing."
                        }
                    }
                    else {
                        Write-Host "Validation of $($file.Name) failed. Output:" -ForegroundColor Red
                        Write-Host $outputString -ForegroundColor Red
                        throw "Copilot exited with code $LASTEXITCODE"
                    }
                }

                $currentCount = 0
                [System.Threading.Monitor]::Enter($syncHash.SyncRoot)
                try {
                    $syncHash.CompletedCount++
                    $currentCount = $syncHash.CompletedCount
                }
                finally {
                    [System.Threading.Monitor]::Exit($syncHash.SyncRoot)
                }
                Write-Host "Validated $($file.Name) ($currentCount/$totalTasks)" -ForegroundColor Green
                $success = $true
            }
            catch {
                $retryCount++
                if ($retryCount -gt $maxRetries) {
                    Write-Error "Failed to validate $($file.Name) after $maxRetries retries: $_"
                    $syncHash.HasError = $true
                    $success = $true
                }
                else {
                    Write-Host "Validation of $($file.Name) failed. Retrying in 1 minute... (Attempt $retryCount/$maxRetries). Error: $_" -ForegroundColor Yellow
                    Start-Sleep -Seconds 60
                }
            }
        }

    } -ThrottleLimit $MaxParallel

    if ($syncHash.HasError) {
        throw "Execution stopped due to errors in one or more validation tasks."
    }

    Write-Host "All validations completed successfully." -ForegroundColor Cyan
}
finally {
    Pop-Location
}
