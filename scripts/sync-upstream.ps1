<#
.SYNOPSIS
    Sync this personal fork with obra/superpowers and refresh the installed plugin.

.DESCRIPTION
    Fetches upstream, merges upstream/main into the current branch, keeps the
    fork-local manifest tweaks intact, pushes to origin, and refreshes the
    Claude Code marketplace + plugin so new skills are live after a restart.

.EXAMPLE
    powershell -ExecutionPolicy Bypass -File scripts\sync-upstream.ps1
    powershell -ExecutionPolicy Bypass -File scripts\sync-upstream.ps1 -SkipPush -SkipPluginUpdate
#>
[CmdletBinding()]
param(
    [string]$Branch = 'main',
    [switch]$SkipPush,
    [switch]$SkipPluginUpdate
)

$ErrorActionPreference = 'Stop'
$repoRoot = Split-Path -Parent $PSScriptRoot
Set-Location $repoRoot

# Manifests this fork deliberately differs from upstream on. They carry the
# personal marketplace name and, crucially, no "version" field - that is what
# makes Claude Code track the plugin by commit sha instead of by version.
$personalManifests = @('.claude-plugin/plugin.json', '.claude-plugin/marketplace.json')

function Invoke-Git {
    param([Parameter(ValueFromRemainingArguments = $true)][string[]]$GitArgs)
    & git @GitArgs
    if ($LASTEXITCODE -ne 0) { throw "git $($GitArgs -join ' ') failed (exit $LASTEXITCODE)" }
}

function Remove-VersionFields {
    # Returns the files it had to strip a "version" field from.
    $changed = @()
    foreach ($file in $personalManifests) {
        if (-not (Test-Path $file)) { continue }
        $text = Get-Content -Raw $file
        $stripped = [regex]::Replace($text, '(?m)^[ \t]*"version":[ \t]*"[^"]*",[ \t]*\r?\n', '')
        if ($stripped -ne $text) {
            $null = $stripped | ConvertFrom-Json   # refuse to write invalid JSON
            [System.IO.File]::WriteAllText((Resolve-Path $file), $stripped)
            $changed += $file
        }
    }
    return $changed
}

# 1. Refuse to merge on top of uncommitted work.
$dirty = & git status --porcelain
if ($dirty) {
    Write-Host "Working tree is dirty. Commit or stash first:" -ForegroundColor Yellow
    $dirty | ForEach-Object { Write-Host "  $_" }
    exit 1
}

$current = (& git rev-parse --abbrev-ref HEAD).Trim()
if ($current -ne $Branch) {
    Write-Host "Switching from '$current' to '$Branch'..." -ForegroundColor Cyan
    Invoke-Git checkout $Branch
}

# 2. Pull upstream history.
Write-Host "Fetching upstream..." -ForegroundColor Cyan
Invoke-Git fetch upstream --prune

$behind = (& git rev-list --count "$Branch..upstream/main").Trim()
if ($behind -eq '0') {
    Write-Host "Already up to date with upstream/main." -ForegroundColor Green
} else {
    Write-Host "Merging $behind new upstream commit(s)..." -ForegroundColor Cyan
    & git merge --no-edit upstream/main
    if ($LASTEXITCODE -ne 0) {
        $conflicts = @(& git diff --name-only --diff-filter=U)
        $unexpected = @($conflicts | Where-Object { $personalManifests -notcontains $_ })
        if ($conflicts.Count -gt 0 -and $unexpected.Count -eq 0) {
            Write-Host "Keeping fork-local manifests over upstream's:" -ForegroundColor Yellow
            foreach ($file in $conflicts) {
                Write-Host "  $file"
                Invoke-Git checkout --ours -- $file
                Invoke-Git add $file
            }
            Invoke-Git commit --no-edit
        } else {
            Write-Host ""
            Write-Host "Merge conflict. Resolve these files, then run the script again:" -ForegroundColor Yellow
            $conflicts | ForEach-Object { Write-Host "  $_" }
            Write-Host "  git add <files>; git commit" -ForegroundColor Yellow
            exit 1
        }
    }

    # An upstream release bumps the version field back in; strip it again so
    # `claude plugin update` keeps seeing every new commit.
    $restored = Remove-VersionFields
    if ($restored.Count -gt 0) {
        Write-Host "Stripping upstream version field from: $($restored -join ', ')" -ForegroundColor Yellow
        Invoke-Git add @personalManifests
        Invoke-Git commit -m "chore: keep fork manifests version-less after upstream merge"
    }
}

# 3. Publish to the fork so other machines install the same code.
if (-not $SkipPush) {
    Write-Host "Pushing to origin/$Branch..." -ForegroundColor Cyan
    Invoke-Git push origin $Branch
}

# 4. Refresh the local Claude Code install.
if (-not $SkipPluginUpdate) {
    if (Get-Command claude -ErrorAction SilentlyContinue) {
        Write-Host "Refreshing Claude Code plugin..." -ForegroundColor Cyan
        & claude plugin marketplace update superpowers-personal
        & claude plugin update superpowers@superpowers-personal
        Write-Host "Restart Claude Code to load the updated skills." -ForegroundColor Green
    } else {
        Write-Host "claude CLI not found; skipping plugin refresh." -ForegroundColor Yellow
    }
}

Write-Host "Done." -ForegroundColor Green
