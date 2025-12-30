param (
    # The URL of the Pull Request to process (e.g., https://github.com/owner/repo/pull/123)
    [Parameter(Mandatory = $true)]
    [string]$PrUrl,

    # The directory where the 'src' folder will be created to store the downloaded files
    [Parameter(Mandatory = $true)]
    [string]$TargetDir
)

$srcDir = Join-Path $TargetDir "src"

if (Test-Path $srcDir) {
    Write-Host "Source directory already exists. Skipping code preparation."
    exit 0
}

# Ensure gh is installed
if (-not (Get-Command "gh" -ErrorAction SilentlyContinue)) {
    Write-Error "GitHub CLI (gh) is not installed or not in the PATH."
    exit 1
}

Write-Host "Fetching PR details from: $PrUrl"

# Retrieve PR information: head repository, head commit SHA, and PR number
try {
    $prData = gh pr view "$PrUrl" --json "headRepository,headRepositoryOwner,headRefOid,number" | ConvertFrom-Json
}
catch {
    Write-Error "Failed to fetch PR details. Please check the URL and ensure you are authenticated with 'gh auth login'."
    exit 1
}

$headRepo = $prData.headRepository.nameWithOwner
if ([string]::IsNullOrEmpty($headRepo)) {
    $headRepo = "$($prData.headRepositoryOwner.login)/$($prData.headRepository.name)"
}

$ref = $prData.headRefOid
$prNumber = $prData.number

# Extract base repository from the PR URL
try {
    $uri = [System.Uri]$PrUrl
    # Segments are like: "/", "owner/", "repo/", "pull/", "number"
    if ($uri.Segments.Count -lt 3) {
        throw "Invalid PR URL format."
    }
    $owner = $uri.Segments[1].Trim('/')
    $repoName = $uri.Segments[2].Trim('/')
    $baseRepo = "$owner/$repoName"
}
catch {
    Write-Error "Failed to parse base repository from URL: $_"
    exit 1
}

# Fetch files using gh api to get the 'status' field
# gh api handles pagination automatically with --paginate if needed, but here we just fetch all
try {
    $files = gh api "repos/$baseRepo/pulls/$prNumber/files" --paginate | ConvertFrom-Json
}
catch {
    Write-Error "Failed to fetch PR files."
    exit 1
}

if (-not $files) {
    Write-Host "No files found in the PR."
    exit 0
}

# Filter files based on requirements
$filesToDownload = $files | Where-Object {
    # 2a. Filter out newly added files (keep only files with status 'added')
    if ($_.status -ne "added") { return $false }

    # 2b. Filter specific paths and extensions
    # Note: gh api returns 'filename' instead of 'path'
    # Requirement: '.go' files starting with "internal/services/"
    # Requirement: '.markdown' files starting with "website/docs/"
    $isGoService = ($_.filename -like "internal/services/*.go")
    $isMarkdownDoc = ($_.filename -like "website/docs/*.markdown")

    return ($isGoService -or $isMarkdownDoc)
}

if (-not $filesToDownload) {
    Write-Error "No newly added code or documentation found."
    exit 1
}

try {
    New-Item -ItemType Directory -Path $srcDir -Force | Out-Null

    foreach ($file in $filesToDownload) {
        $filePath = $file.filename
        Write-Host "Processing: $filePath"

        # 3. Create parent folders and download
        $destFilePath = Join-Path $srcDir $filePath
        $parentDir = Split-Path $destFilePath -Parent

        if (-not (Test-Path $parentDir)) {
            New-Item -ItemType Directory -Path $parentDir -Force | Out-Null
        }

        # Download file using gh api
        # We use the raw media type header to retrieve the file content directly.
        # We target the head repository and the specific commit SHA ($ref) to ensure we get the version from the PR.
        try {
            $apiPath = "repos/$headRepo/contents/$filePath`?ref=$ref"
            $content = gh api $apiPath -H "Accept: application/vnd.github.v3.raw"
            
            # Write the content to the destination file
            # Using Set-Content with UTF8 encoding
            $content | Set-Content -Path $destFilePath -Encoding UTF8 -Force
            Write-Host "Downloaded to: $destFilePath"
        }
        catch {
            throw "Failed to download $filePath. Error: $_"
        }
    }
    Write-Host "Download complete."
}
catch {
    Write-Error "An error occurred during preparation: $_"
    if (Test-Path $srcDir) {
        Remove-Item -Path $srcDir -Recurse -Force
        Write-Host "Cleaned up $srcDir due to error."
    }
    exit 1
}
