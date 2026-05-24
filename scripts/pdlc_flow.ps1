param(
    [ValidateSet("client-support-plan", "sla-indicators")]
    [string]$Profile = "client-support-plan",
    [string]$FeatureName = "",
    [string]$FeatureBranch = "",
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

function Get-FlowProfile {
    param([string]$Name)
    switch ($Name) {
        "sla-indicators" {
            return @{
                FeatureName = "sla-indicators"
                FeatureBranch = "codex/pdlc-sla-indicators"
                PrTitle = "PDLC: SLA indicators"
                PrBody = "Automated PDLC flow: SLA requirements, QA review, manual test case, frontend implementation, and UI automated coverage."
                Stages = @(
                    @{ Message = "docs: add sla indicators requirements"; Paths = @("docs/requirements/ui-sla-indicators.md") },
                    @{ Message = "docs: add qa review for sla indicators"; Paths = @("docs/qa-reviews/ui-sla-indicators-review.md") },
                    @{ Message = "feat: add sla indicators ui"; Paths = @("frontend/src/App.tsx", "frontend/src/App.css") },
                    @{ Message = "test: add manual case for sla indicators"; Paths = @("tests/manual/ui-sla-indicators.md", "docs/test-runs/ui-sla-indicators-manual.md") },
                    @{ Message = "test: add automated ui coverage for sla indicators"; Paths = @("tests/ui") },
                    @{ Message = "chore: generalize pdlc flow runner"; Paths = @("scripts/pdlc_flow.ps1", "docs/pdlc-workflows/automated-flow.md") }
                )
            }
        }
        default {
            return @{
                FeatureName = "client-support-plan"
                FeatureBranch = "codex/pdlc-client-support-plan"
                PrTitle = "PDLC: client support plan"
                PrBody = "Automated PDLC flow: requirements, QA review, manual test case, frontend implementation, and UI automated coverage."
                Stages = @(
                    @{ Message = "docs: add client support plan requirements"; Paths = @("docs/requirements/ui-client-support-plan.md") },
                    @{ Message = "docs: add qa review workflow and requirements review"; Paths = @("docs/pdlc-workflows", "docs/qa-reviews") },
                    @{ Message = "test: add manual case for client support plan"; Paths = @("tests/manual", "docs/test-runs") },
                    @{ Message = "feat: add client support plan ui"; Paths = @("frontend/src/App.tsx", "frontend/src/App.css") },
                    @{ Message = "test: add automated ui coverage for client support plan"; Paths = @("tests/ui") }
                )
            }
        }
    }
}

$Flow = Get-FlowProfile $Profile
if (-not $FeatureName) {
    $FeatureName = $Flow.FeatureName
}
if (-not $FeatureBranch) {
    $FeatureBranch = $Flow.FeatureBranch
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

function Invoke-GitChecked {
    param([string[]]$Arguments)
    Write-Host "PS> git -c safe.directory=`"$GitSafeDirectory`" $($Arguments -join ' ')" -ForegroundColor DarkGray
    if ($DryRun) {
        return
    }
    & git -c "safe.directory=$GitSafeDirectory" @Arguments
    if ($LASTEXITCODE -ne 0) {
        throw "Git command failed with exit code $LASTEXITCODE`: git $($Arguments -join ' ')"
    }
}

function Invoke-NativeChecked {
    param(
        [string]$FilePath,
        [string[]]$Arguments,
        [string]$WorkingDirectory = (Get-Location).Path
    )
    Write-Host "PS> $FilePath $($Arguments -join ' ')" -ForegroundColor DarkGray
    if ($DryRun) {
        return
    }
    Push-Location $WorkingDirectory
    try {
        & $FilePath @Arguments
        if ($LASTEXITCODE -ne 0) {
            throw "Command failed with exit code $LASTEXITCODE`: $FilePath $($Arguments -join ' ')"
        }
    }
    finally {
        Pop-Location
    }
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
    $sourceGitUrl = "file:///" + ($sourceRoot.Replace("\", "/").Replace(" ", "%20"))
    $gitExecPath = (& git --exec-path).Trim()
    $uploadPack = Join-Path $gitExecPath "git-upload-pack.exe"
    if ($uploadPack -like "C:\Program Files\Git\mingw64\*") {
        $uploadPack = $uploadPack.Replace("C:\Program Files\Git\mingw64", "/mingw64").Replace("\", "/")
    }

    Write-Step "Clone local base branch into isolated Git repository"
    Invoke-NativeChecked "git" @("clone", "--upload-pack", $uploadPack, "--no-hardlinks", "--branch", $BaseBranch, $sourceGitUrl, $isolatedRoot)
    Invoke-NativeChecked "git" @("remote", "set-url", "origin", $remote) $isolatedRoot
    Invoke-NativeChecked "git" @("config", "user.name", "AI-PDLC Bot") $isolatedRoot
    Invoke-NativeChecked "git" @("config", "user.email", "ai-pdlc-bot@example.local") $isolatedRoot
    Invoke-NativeChecked "git" @("checkout", "-B", $FeatureBranch) $isolatedRoot

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
    Invoke-Checked "powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\pdlc_flow.ps1 -Profile `"$Profile`" -FeatureName `"$FeatureName`" -FeatureBranch `"$FeatureBranch`" -BaseBranch `"$BaseBranch`" -SkipChecks $(if ($SkipPush) { '-SkipPush' }) $(if ($SkipPr) { '-SkipPr' })" $isolatedRoot
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
        Invoke-GitChecked @("switch", $FeatureBranch)
    }
    else {
        Invoke-GitChecked @("switch", "-c", $FeatureBranch)
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
            Invoke-GitChecked @("add", "--", $path)
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

    Invoke-GitChecked @("commit", "-m", $Message)
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
    Invoke-GitChecked @("push", "-u", "origin", $FeatureBranch)
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
        title = $Flow.PrTitle
        head  = $FeatureBranch
        base  = $BaseBranch
        body  = $Flow.PrBody
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

foreach ($stage in $Flow.Stages) {
    Commit-Stage $stage.Message $stage.Paths
}

if (-not $SkipChecks) {
    Run-Checks
}
Show-LargestTrackedFiles
Push-Branch
Create-PullRequest

Write-Step "PDLC flow completed"
Invoke-Git @("log", "--oneline", "-5")
