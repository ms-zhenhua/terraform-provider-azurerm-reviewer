param(
    [Parameter(Mandatory = $true)]
    [string]$PullRequestLink,

    [string]$Model,

    [int]$MaxParallel = 3,

    [switch]$ForceNew
)

# Create pull_requests directory if it doesn't exist
$root = Split-Path -Parent $PSScriptRoot
$pullRequestsDir = Join-Path $root "pull_requests"
if (-not (Test-Path $pullRequestsDir)) {
    New-Item -ItemType Directory -Path $pullRequestsDir -Force | Out-Null
    Write-Host "Created root folder: $pullRequestsDir"
}

# Parse the URL to extract owner, repo, and id
# Pattern matches: https://github.com/<owner>/<repo>/pull/<id>
if ($PullRequestLink -match 'github\.com/(?<owner>[^/]+)/(?<repo>[^/]+)/pull/(?<id>\d+)') {
    $owner = $Matches.owner
    $repo = $Matches.repo
    $id = $Matches.id
    
    $dirName = "${owner}_${repo}_${id}"
    
    # Determine the target path. 
    # We want to create the folder in the pull_requests directory
    $targetDir = Join-Path $pullRequestsDir $dirName

    if ($ForceNew -and (Test-Path $targetDir)) {
        Remove-Item -Path $targetDir -Recurse -Force
        Write-Host "Deleted existing folder: $targetDir"
    }

    if (-not (Test-Path $targetDir)) {
        New-Item -ItemType Directory -Path $targetDir -Force | Out-Null
        Write-Host "Created folder: $targetDir"
    }
    else {
        Write-Host "Folder already exists: $targetDir"
    }

    # Invoke prepare_code.ps1
    $prepareScript = Join-Path $PSScriptRoot "prepare_code.ps1"
    Write-Host "Invoking prepare_code.ps1..."
    & $prepareScript -PrUrl $PullRequestLink -TargetDir $targetDir

    # Invoke generate_tasks.ps1
    $generateTasksScript = Join-Path $PSScriptRoot "generate_tasks.ps1"
    Write-Host "Invoking generate_tasks.ps1..."
    & $generateTasksScript -TargetDir $targetDir

    # Invoke run_tasks.ps1
    $runTasksScript = Join-Path $PSScriptRoot "run_tasks.ps1"
    Write-Host "Invoking run_tasks.ps1..."
    if ($Model) {
        & $runTasksScript -TargetDir $targetDir -Model $Model -MaxParallel $MaxParallel
    }
    else {
        & $runTasksScript -TargetDir $targetDir -MaxParallel $MaxParallel
    }

    # Invoke generate_report.ps1
    $generateReportScript = Join-Path $PSScriptRoot "generate_report.ps1"
    Write-Host "Invoking generate_report.ps1..."
    if ($Model) {
        & $generateReportScript -TargetDir $targetDir -Model $Model
    }
    else {
        & $generateReportScript -TargetDir $targetDir
    }
}
else {
    Write-Error "Invalid Pull Request Link. Format should be https://github.com/<owner>/<repo>/pull/<id>"
}
