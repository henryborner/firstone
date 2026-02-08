# sync.ps1 - Git Sync Script
param(
    [string]$Message = "",
    [switch]$NoPull,
    [switch]$NoPush,
    [switch]$Force,
    [switch]$StatusOnly
)

Write-Host "=== Git Sync ===" -ForegroundColor Cyan
Write-Host "Repository: $(git config --get remote.origin.url)" -ForegroundColor Gray
Write-Host "Time: $(Get-Date -Format 'HH:mm:ss')" -ForegroundColor Gray

# Only show status
if ($StatusOnly) {
    Write-Host "`nGit status:" -ForegroundColor Yellow
    git status
    Write-Host "`nCommit history:" -ForegroundColor Yellow
    git log --oneline -5
    exit 0
}

# Pull updates (unless specified not to)
if (-not $NoPull) {
    Write-Host "`nPulling remote updates..." -ForegroundColor Yellow
    if ($Force) {
        git pull --rebase origin main
    } else {
        git pull origin main
    }
    
    if ($LASTEXITCODE -eq 0) {
        Write-Host "SUCCESS: Pull completed" -ForegroundColor Green
    } else {
        Write-Host "WARNING: Pull failed or already up to date" -ForegroundColor Yellow
    }
}

# Check local changes
Write-Host "`nChecking local changes..." -ForegroundColor Yellow
$changes = git status --porcelain

if ($changes) {
    Write-Host "Found changes:" -ForegroundColor Cyan
    git status --short
    
    # Determine commit message
    if ([string]::IsNullOrWhiteSpace($Message)) {
        $Message = "Update $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
    }
    
    # Commit
    Write-Host "`nCommitting: $Message" -ForegroundColor Green
    git add .
    git commit -m $Message
    
    # Push (unless specified not to)
    if (-not $NoPush) {
        Write-Host "`nPushing to GitHub..." -ForegroundColor Yellow
        git push origin main
        
        if ($LASTEXITCODE -eq 0) {
            Write-Host "SUCCESS: Push completed!" -ForegroundColor Green
            Write-Host "Repository: https://github.com/henryborner/firstone" -ForegroundColor Cyan
        } else {
            Write-Host "ERROR: Push failed" -ForegroundColor Red
        }
    }
} else {
    Write-Host "No local changes to commit" -ForegroundColor Green
}

Write-Host "`nSync completed" -ForegroundColor Green
Write-Host "Branch: $(git branch --show-current)" -ForegroundColor Gray
Write-Host "Latest commit: $(git log --oneline -1)" -ForegroundColor Gray