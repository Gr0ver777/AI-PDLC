param(
    [string]$FeatureName = "client-support-plan",
    [string]$FeatureBranch = "codex/pdlc-client-support-plan",
    [string]$BaseBranch = "main",
    [switch]$RepairGitAcl,
    [switch]$UseIsolatedGitWorkspace,
    [switch]$SkipPush,
    [switch]$SkipPr,
    [switch]$SkipChecks,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"
$RepoRoot = (Resolve-Path ".").Path
$GitSafeDirectory = $RepoRoot.Replace("\", "/")

function Write-Step {
    param([string]$Message)
    Write-Host ""
    Write-Host "==> $Message" -ForegroundColor Cyan
}

function Invoke-Checked {
    param(
        [string]$Command,
        [string]$WorkingDirectory = (Get-Location).Path
    )
    Write-Host "PS> $Command" -ForegroundColor DarkGray
    if ($DryRun) {
        return
    }
    Push-Location $WorkingDirectory
    try {
        powershell -NoProfile -ExecutionPolicy Bypass -Command $Command
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE`: $Command"
        }
    }
    finally {
        Pop-Location
    }
}

function Invoke-Git {
    param([string[]]$Arguments)
    & git -c "safe.directory=$GitSafeDirectory" @Arguments
}

function Git-Command {
    param([string]$Arguments)
    return "git -c safe.directory=`"$GitSafeDirectory`" $Arguments"
}

function Test-GitWriteAccess {
    $testFile = Join-Path ".git" "codex-write-test.tmp"
    try {
        "write-test" | Set-Content -LiteralPath $testFile -Encoding UTF8
        Remove-Item -LiteralPath $testFile -Force
        return $true
    }
    catch {
        Write-Host "Git write preflight failed: $($_.Exception.Message)" -ForegroundColor Yellow
        return $false
    }
}

function Repair-GitAcl {
    $gitPath = (Resolve-Path ".git").Path
    $user = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
    Write-Step "Repair Git ACL for $user"
    Invoke-Checked "icacls `"$gitPath`" /inheritance:e"
    Invoke-Checked "icacls `"$gitPath`" /grant `"$user`":(OI)(CI)M /T"
}

function Invoke-IsolatedGitWorkspace {
    $sourceRoot = (Resolve-Path ".").Path
    $runRoot = Join-Path $sourceRoot ".pdlc-run"
    $isolatedRoot = Join-Path $runRoot "worktree"
    $remote = Invoke-Git @("remote", "get-url", "origin")

    Write-Step "Prepare isolated Git workspace"
    if (Test-Path -LiteralPath $isolatedRoot) {
        Remove-Item -LiteralPath $isolatedRoot -Recurse -Force
    }
    New-Item -ItemType Directory -Path $isolatedRoot | Out-Null

    Write-Step "Initialize isolated Git repository"
    Invoke-Checked "git init" $isolatedRoot
    Invoke-Checked "git remote add origin `"$remote`"" $isolatedRoot
    Invoke-Checked "git config user.name `"AI-PDLC Bot`"" $isolatedRoot
    Invoke-Checked "git config user.email `"ai-pdlc-bot@example.local`"" $isolatedRoot
    Invoke-Checked "git fetch origin $BaseBranch --depth=1" $isolatedRoot
    Invoke-Checked "git checkout -B $FeatureBranch FETCH_HEAD" $isolatedRoot

    $excludeDirs = @(
        ".git", ".pdlc-run", ".pw-browsers", ".venv", ".npm-cache", ".python-packages",
        ".allure-plugin", "frontend/node_modules", "frontend/dist", "backend/build",
        "backend/data", "tests/allure-results"
    )
    $excludeFiles = @("backend.zip", "*.log", "*.err", "*.pyc")

    $robocopyArgs = @($sourceRoot, $isolatedRoot, "/E", "/NFL", "/NDL", "/NJH", "/NJS", "/NP")
    foreach ($dir in $excludeDirs) {
        $robocopyArgs += "/XD"
        $robocopyArgs += (Join-Path $sourceRoot $dir)
    }
    foreach ($file in $excludeFiles) {
        $robocopyArgs += "/XF"
        $robocopyArgs += $file
    }

    & robocopy @robocopyArgs | Out-Null
    if ($LASTEXITCODE -gt 7) {
        throw "robocopy failed with exit code $LASTEXITCODE"
    }

    Write-Step "Run PDLC flow inside isolated workspace"
    Invoke-Checked "powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\pdlc_flow.ps1 -FeatureName `"$FeatureName`" -FeatureBranch `"$FeatureBranch`" -BaseBranch `"$BaseBranch`" -SkipChecks $(if ($SkipPush) { '-SkipPush' }) $(if ($SkipPr) { '-SkipPr' })" $isolatedRoot
}

function Assert-NoForbiddenTrackedFiles {
    $patterns = @(
        "^\.pw-browsers/",
        "^\.venv/",
        "^\.npm-cache/",
        "^\.python-packages/",
        "^\.allure-plugin/",
        "node_modules/",
        "__pycache__/",
        "\.pyc$",
        "/dist/",
        "allure-results/"
    )
    $tracked = Invoke-Git @("ls-files")
    foreach ($file in $tracked) {
        foreach ($pattern in $patterns) {
            if ($file -match $pattern) {
                throw "Forbidden tracked file detected: $file"
            }
        }
    }
}

function Show-LargestTrackedFiles {
    Write-Step "Largest tracked files"
    $files = Invoke-Git @("ls-files") | ForEach-Object {
        if (Test-Path -LiteralPath $_) {
            Get-Item -LiteralPath $_
        }
    } | Sort-Object Length -Descending | Select-Object -First 15 FullName, Length
    $files | Format-Table -AutoSize
}

function Ensure-Branch {
    Write-Step "Ensure feature branch $FeatureBranch"
    $current = Invoke-Git @("branch", "--show-current")
    if ($current -eq $FeatureBranch) {
        return
    }
    $exists = Invoke-Git @("branch", "--list", $FeatureBranch)
    if ($exists) {
        Invoke-Checked (Git-Command "switch $FeatureBranch")
    }
    else {
        Invoke-Checked (Git-Command "switch -c $FeatureBranch")
    }
}

function Commit-Stage {
    param(
        [string]$Message,
        [string[]]$Paths
    )
    Write-Step "Commit: $Message"
    Assert-NoForbiddenTrackedFiles

    foreach ($path in $Paths) {
        if (Test-Path -LiteralPath $path) {
            Invoke-Checked (Git-Command "add -- `"$path`"")
        }
        else {
            Write-Host "Skip missing path: $path" -ForegroundColor Yellow
        }
    }

    $staged = Invoke-Git @("diff", "--cached", "--name-only")
    if (-not $staged) {
        Write-Host "No staged changes for stage: $Message" -ForegroundColor Yellow
        return
    }

    Invoke-Checked (Git-Command "commit -m `"$Message`"")
    Invoke-Git @("log", "--oneline", "-1")
}

function Run-Checks {
    Write-Step "Frontend lint"
    Invoke-Checked "npm.cmd run lint" "frontend"

    Write-Step "Frontend build"
    Invoke-Checked "npm.cmd run build" "frontend"

    Write-Step "UI tests"
    $pwPath = (Resolve-Path ".pw-browsers" -ErrorAction SilentlyContinue)
    if ($pwPath) {
        $env:PLAYWRIGHT_BROWSERS_PATH = $pwPath.Path
    }
    Invoke-Checked "python -m pytest tests\ui -q"
}

function Push-Branch {
    if ($SkipPush) {
        Write-Host "Skip push requested." -ForegroundColor Yellow
        return
    }
    Write-Step "Push feature branch"
    Invoke-Checked (Git-Command "push -u origin $FeatureBranch")
}

function Create-PullRequest {
    if ($SkipPr) {
        Write-Host "Skip PR requested." -ForegroundColor Yellow
        return
    }

    $remote = Invoke-Git @("remote", "get-url", "origin")
    if ($remote -notmatch "github\.com[:/](?<owner>[^/]+)/(?<repo>[^/.]+)(\.git)?$") {
        Write-Host "Cannot infer GitHub owner/repo from remote: $remote" -ForegroundColor Yellow
        return
    }
    $owner = $Matches.owner
    $repo = $Matches.repo
    $compareUrl = "https://github.com/$owner/$repo/compare/$BaseBranch...$FeatureBranch?expand=1"

    if (-not $env:GITHUB_TOKEN) {
        Write-Host "GITHUB_TOKEN is not set. Open PR manually:" -ForegroundColor Yellow
        Write-Host $compareUrl
        return
    }

    Write-Step "Create pull request"
    $body = @{
        title = "PDLC: client support plan"
        head  = $FeatureBranch
        base  = $BaseBranch
        body  = "Automated PDLC flow: requirements, QA review, manual test case, frontend implementation, and UI automated coverage."
    } | ConvertTo-Json

    $headers = @{
        Authorization = "Bearer $env:GITHUB_TOKEN"
        Accept        = "application/vnd.github+json"
        "X-GitHub-Api-Version" = "2022-11-28"
    }
    try {
        $response = Invoke-RestMethod -Uri "https://api.github.com/repos/$owner/$repo/pulls" -Method Post -Headers $headers -Body $body -ContentType "application/json"
        Write-Host "PR created: $($response.html_url)" -ForegroundColor Green
    }
    catch {
        Write-Host "GitHub API did not allow PR creation with the current token." -ForegroundColor Yellow
        Write-Host "Required token access: repository selected, Contents read/write, Pull requests read/write." -ForegroundColor Yellow
        Write-Host "Open PR manually:" -ForegroundColor Yellow
        Write-Host $compareUrl
    }
}

Write-Step "PDLC flow preflight"
if ($RepairGitAcl) {
    Repair-GitAcl
}

Invoke-Git @("status", "--short", "--branch")

if (-not (Test-GitWriteAccess)) {
    if ($UseIsolatedGitWorkspace) {
        if (-not $SkipChecks) {
            Run-Checks
        }
        Invoke-IsolatedGitWorkspace
        return
    }
    throw "Cannot write to .git. Run: .\scripts\pdlc_flow.ps1 -RepairGitAcl -DryRun:`$false, or execute the icacls commands from an elevated/user PowerShell."
}

Assert-NoForbiddenTrackedFiles
Show-LargestTrackedFiles
Ensure-Branch

if (-not $SkipChecks) {
    Run-Checks
}

Commit-Stage "docs: add client support plan requirements" @(
    "docs/requirements/ui-client-support-plan.md"
)

Commit-Stage "docs: add qa review workflow and requirements review" @(
    "docs/pdlc-workflows",
    "docs/qa-reviews"
)

Commit-Stage "test: add manual case for client support plan" @(
    "tests/manual",
    "docs/test-runs"
)

Commit-Stage "feat: add client support plan ui" @(
    "frontend/src/App.tsx",
    "frontend/src/App.css"
)

Commit-Stage "test: add automated ui coverage for client support plan" @(
    "tests/ui"
)

if (-not $SkipChecks) {
    Run-Checks
}
Show-LargestTrackedFiles
Push-Branch
Create-PullRequest

Write-Step "PDLC flow completed"
Invoke-Git @("log", "--oneline", "-5")
