param (
    [Parameter(Mandatory = $true)]
    [string]$TargetDir,


    [string]$Model
)

$ErrorActionPreference = "Stop"

$reportTxtPath = Join-Path -Path $TargetDir -ChildPath "report.txt"
$reportMdPath = Join-Path -Path $TargetDir -ChildPath "report.md"
$taskResultsDir = Join-Path -Path $TargetDir -ChildPath "task_results"

try {
    # 2. combine json array in each file under `TargetDir/task_results` into a single json array saved in 'TargetDir/report.txt' if 'TargetDir/report.txt' does not exist
    if (-not (Test-Path -Path $reportTxtPath)) {
        Write-Host "Combining task results into $reportTxtPath..."
        $combinedResults = @()
        
        if (Test-Path -Path $taskResultsDir) {
            $files = Get-ChildItem -Path $taskResultsDir -Filter "*.txt" -File
            foreach ($file in $files) {
                $content = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                if ($content) {
                    $combinedResults += $content
                }
            }
        }
        
        $combinedResults | ConvertTo-Json -Depth 100 | Set-Content -Path $reportTxtPath -Encoding UTF8
    }

    # 3. invoke the following copilot cli command if TargetDir/report.md does not exist
    if (-not (Test-Path -Path $reportMdPath)) {
        Write-Host "Generating $reportMdPath using Copilot CLI..."
        
        # Construct the prompt string dynamically
        $prompt = "generate $reportMdPath and display the content in $reportTxtPath as a table."
        
        # Invoke copilot command
        if ($Model) {
            & copilot -p $prompt --model $Model --allow-all-tools
        }
        else {
            & copilot -p $prompt --allow-all-tools
        }
        
        if ($LASTEXITCODE -ne 0) {
            throw "Copilot CLI command failed with exit code $LASTEXITCODE"
        }
    }
}
catch {
    Write-Error "An error occurred: $_"
    
    # 4. if any error happens, make sure TargetDir/report.txt and TargetDir/report.md are deleted before this script ends
    if (Test-Path -Path $reportTxtPath) {
        Remove-Item -Path $reportTxtPath -Force
        Write-Host "Cleaned up $reportTxtPath"
    }
    
    if (Test-Path -Path $reportMdPath) {
        Remove-Item -Path $reportMdPath -Force
        Write-Host "Cleaned up $reportMdPath"
    }
    
    exit 1
}
