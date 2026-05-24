# Automated PDLC Flow

## Purpose

`scripts/pdlc_flow.ps1` runs the local PDLC delivery flow:

1. Git preflight.
2. Frontend lint/build.
3. UI tests with Playwright route mocking.
4. Stage-specific commits.
5. Push feature branch.
6. Create a pull request when `GITHUB_TOKEN` is available.

## Git Permission Repair

If Git fails with `Unable to create .git/index.lock: Permission denied`, run from the repository root:

```powershell
.\scripts\pdlc_flow.ps1 -RepairGitAcl -DryRun
```

If dry-run shows the intended commands, run:

```powershell
.\scripts\pdlc_flow.ps1 -RepairGitAcl -SkipPush -SkipPr
```

The repair step grants the current Windows user `Modify` permissions on `.git`.

## Full Flow

Every new product feature must start from a dedicated feature branch created from the current `main`.
Do not run PDLC delivery commits directly in `main`, `dev`, or another already shared feature branch.
Use the naming pattern `codex/pdlc-<feature-slug>` unless the team agrees on another explicit branch name.

```powershell
.\scripts\pdlc_flow.ps1
```

Run the SLA indicators flow:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\pdlc_flow.ps1 -Profile sla-indicators
```

To skip remote operations:

```powershell
.\scripts\pdlc_flow.ps1 -SkipPush -SkipPr
```

To create a PR automatically, set:

```powershell
$env:GITHUB_TOKEN = "<token-with-repo-scope>"
.\scripts\pdlc_flow.ps1
```

For a fine-grained GitHub token, grant access to the target repository and enable:

- `Contents`: read and write
- `Pull requests`: read and write

If `GITHUB_TOKEN` is not set or GitHub returns `403 Resource not accessible by personal access token`, the script prints the GitHub compare URL after push and does not fail the completed PDLC flow.

## Fallback: Isolated Git Workspace

If `.git` ACL cannot be repaired from the current sandbox, run:

```powershell
powershell -NoProfile -ExecutionPolicy Bypass -File .\scripts\pdlc_flow.ps1 -Profile sla-indicators -UseIsolatedGitWorkspace
```

The runner copies the project into `.pdlc-run/worktree`, excludes local caches and browsers, creates a clean Git repository there, commits each PDLC stage, pushes the profile feature branch, and creates or prints the PR link.

In isolated mode, lint/build/UI tests run in the original workspace first. The isolated workspace is used only for Git commit, push, and PR operations.

## Guardrails

The runner fails if Git tracks generated or heavy local artifacts:

- `.pw-browsers`
- `.venv`
- `.npm-cache`
- `.python-packages`
- `.allure-plugin`
- `node_modules`
- `__pycache__`
- `*.pyc`
- `dist`
- `allure-results`
