<#
.SYNOPSIS
    Runs copilot tasks in parallel.
.DESCRIPTION
    Executes tasks defined in 'tasks/*.txt' using the copilot CLI.
    Results are saved to 'task_results/'.
    Supports parallel execution and resuming from previous runs.
.PARAMETER MaxParallel
    Maximum number of parallel tasks to run. Default is 20.
#>
param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,

    [string]$Model,

    [int]$MaxParallel = 3
)

$ErrorActionPreference = "Stop"

# Determine paths
$scriptDir = $PSScriptRoot
$tasksDir = Join-Path $TargetDir "tasks"
$resultsDir = Join-Path $TargetDir "task_results"

# Ensure we are in the target directory for relative paths in copilot commands to work as expected
Push-Location $TargetDir

try {
    # 1. Create task_results folder if it doesn't exist
    if (-not (Test-Path $resultsDir)) {
        New-Item -ItemType Directory -Path $resultsDir -Force | Out-Null
        Write-Host "Created directory: $resultsDir" -ForegroundColor Cyan
    }

    # Get all task files
    if (-not (Test-Path $tasksDir)) {
        Write-Error "Tasks directory not found at $tasksDir. Please run generate_tasks.ps1 first."
        exit 1
    }

    $taskFiles = Get-ChildItem -Path $tasksDir -Filter "*.txt"

    Write-Host "Found $($taskFiles.Count) tasks." -ForegroundColor Cyan

    # Shared state for error handling across parallel threads
    $syncHash = [hashtable]::Synchronized(@{ 
            HasError       = $false
            CompletedCount = 0
        })

    $totalTasks = $taskFiles.Count

    # Run tasks in parallel
    $taskFiles | ForEach-Object -Parallel {
        $file = $_
        $syncHash = $using:syncHash
        $resultsDir = $using:resultsDir
        $TargetDir = $using:TargetDir
        $Model = $using:Model
        $totalTasks = $using:totalTasks

        # Set location to target directory
        Set-Location $TargetDir
        
        # Clear NODE_OPTIONS to prevent VS Code debugger from attaching to parallel processes
        $env:NODE_OPTIONS = $null

        # Check if we should abort due to previous error
        if ($syncHash.HasError) {
            return
        }

        $resultFilePath = Join-Path $resultsDir $file.Name

        # Check if result already exists
        if (Test-Path $resultFilePath) {
            [System.Threading.Monitor]::Enter($syncHash.SyncRoot)
            try { $syncHash.CompletedCount++ } finally { [System.Threading.Monitor]::Exit($syncHash.SyncRoot) }
            Write-Host "Skipping $($file.Name) - Result already exists." -ForegroundColor Gray
            return
        }

        Write-Host "Processing $($file.Name)..." -ForegroundColor Green

        $maxRetries = 3
        $retryCount = 0
        $success = $false

        while (-not $success) {
            try {
                # Construct the command
                $relativePath = "tasks/$($file.Name)"
                $prompt = "Complete the task in $relativePath."
                
                # Run command
                # Capture output to avoid noise, but we expect Copilot to create the file
                if ($Model) {
                    $output = copilot -p $prompt --model $Model --allow-all-tools --allow-all-paths 2>&1
                }
                else {
                    $output = copilot -p $prompt --allow-all-tools --allow-all-paths 2>&1
                }
                $output | Out-String | Write-Host
                
                # Check exit code
                if ($LASTEXITCODE -ne 0) {
                    $outputString = $output | Out-String
                    # Check for known libuv assertion failure on Windows which happens on exit
                    if ($outputString -match "Assertion failed: !\(handle->flags & UV_HANDLE_CLOSING\)") {
                        Write-Host "Task $($file.Name) encountered a known shutdown error (libuv assertion), but likely completed." -ForegroundColor Yellow
                        
                        # Verify if result file exists to be sure
                        if (Test-Path $resultFilePath) {
                            Write-Host "Result file created successfully. Ignoring exit code." -ForegroundColor Green
                        }
                        else {
                            Write-Host "Result file NOT found. Treating as failure." -ForegroundColor Red
                            throw "Copilot exited with code $LASTEXITCODE and result file is missing."
                        }
                    }
                    else {
                        Write-Host "Task $($file.Name) failed. Output:" -ForegroundColor Red
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
                Write-Host "Completed $($file.Name) ($currentCount/$totalTasks)" -ForegroundColor Green
                $success = $true
            }
            catch {
                $retryCount++
                if ($retryCount -gt $maxRetries) {
                    # Report error and signal stop
                    Write-Error "Failed to process $($file.Name) after $maxRetries retries: $_"
                    $syncHash.HasError = $true
                    $success = $true
                }
                else {
                    Write-Host "Task $($file.Name) failed. Retrying in 1 minute... (Attempt $retryCount/$maxRetries). Error: $_" -ForegroundColor Yellow
                    Start-Sleep -Seconds 60
                }
            }
        }

    } -ThrottleLimit $MaxParallel

    if ($syncHash.HasError) {
        throw "Execution stopped due to errors in one or more tasks."
    }

    Write-Host "All tasks completed successfully." -ForegroundColor Cyan
}
finally {
    Pop-Location
}
