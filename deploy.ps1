$ErrorActionPreference = "Continue"
Set-Location -LiteralPath $PSScriptRoot

Write-Host "==========================================" -ForegroundColor Cyan
Write-Host "  AMU KARA - GitHub Pages Auto Deployer" -ForegroundColor Cyan
Write-Host "==========================================" -ForegroundColor Cyan
Write-Host ""

# 1. Remove GITHUB_TOKEN env var to avoid Windows Git credential conflict
Remove-Item Env:\GITHUB_TOKEN -ErrorAction SilentlyContinue
Remove-Item Env:\GH_TOKEN -ErrorAction SilentlyContinue

# 2. Fix nested folder permissions and move files to root if needed
if (Test-Path -LiteralPath ".\amukara-pages") {
    Write-Host "[1/4] Preparing files..." -ForegroundColor Yellow
    icacls ".\amukara-pages" /inheritance:e /T | Out-Null
    Get-ChildItem -LiteralPath ".\amukara-pages" -Force | ForEach-Object {
        $dest = Join-Path $PSScriptRoot $_.Name
        if (-not (Test-Path -LiteralPath $dest)) {
            Move-Item -LiteralPath $_.FullName -Destination $PSScriptRoot -Force
        }
    }
    if ((Get-ChildItem -LiteralPath ".\amukara-pages" -Force | Measure-Object).Count -eq 0) {
        Remove-Item -LiteralPath ".\amukara-pages" -Force
    }
}

# Create .nojekyll so GitHub Pages serves all assets (.mjs, .onnx) as-is
if (-not (Test-Path -LiteralPath ".\.nojekyll")) {
    New-Item -ItemType File -Path ".\.nojekyll" -Force | Out-Null
}

# 3. Initialize Git repository in this folder
Write-Host "[2/4] Committing changes..." -ForegroundColor Yellow
if (-not (Test-Path -LiteralPath ".\.git")) {
    git init
}
git branch -M main

$gitName = (git config user.name)
if ([string]::IsNullOrWhiteSpace($gitName)) {
    git config user.name "amukara-user"
}
$gitEmail = (git config user.email)
if ([string]::IsNullOrWhiteSpace($gitEmail)) {
    git config user.email "amukara-user@users.noreply.github.com"
}

git add -A
git commit -m "Update AMU KARA for GitHub Pages"

# 4. Push to GitHub
Write-Host "[3/4] Pushing to GitHub..." -ForegroundColor Yellow
$repoName = "amukara-pages"
$ghUser = $null
try {
    $ghUser = (gh api user --jq .login 2>$null)
    if ($ghUser) { $ghUser = $ghUser.Trim() }
} catch {}

if (-not [string]::IsNullOrWhiteSpace($ghUser)) {
    $remoteUrl = "https://github.com/$ghUser/$repoName.git"
    git remote set-url origin $remoteUrl 2>$null
    git push -u origin main

    $pagesUrl = "https://$ghUser.github.io/$repoName/"
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  UPDATE COMPLETE!" -ForegroundColor Green
    Write-Host "  URL: $pagesUrl" -ForegroundColor Green
    Write-Host "  (Wait ~1 minute, then reload the page)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Green
} else {
    git push -u origin main
    Write-Host "UPDATE COMPLETE!" -ForegroundColor Green
}

Write-Host ""
Read-Host "Press Enter to close this window"
