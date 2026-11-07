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
    Write-Host "[1/5] Preparing files..." -ForegroundColor Yellow
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
Write-Host "[2/5] Initializing Git repository..." -ForegroundColor Yellow
if (-not (Test-Path -LiteralPath ".\.git")) {
    git init
}
git branch -M main

# Ensure git user.name and user.email are set locally
$gitName = (git config user.name)
if ([string]::IsNullOrWhiteSpace($gitName)) {
    git config user.name "amukara-user"
}
$gitEmail = (git config user.email)
if ([string]::IsNullOrWhiteSpace($gitEmail)) {
    git config user.email "amukara-user@users.noreply.github.com"
}

Write-Host "[3/5] Committing files (including 52MB AI model, please wait)..." -ForegroundColor Yellow
git add -A
git commit -m "Deploy AMU KARA to GitHub Pages"

# 4. Check GitHub CLI authentication and create/push repository
Write-Host "[4/5] Connecting to GitHub..." -ForegroundColor Yellow
$repoName = "amukara-pages"
$ghUser = $null
try {
    $ghUser = (gh api user --jq .login 2>$null)
    if ($ghUser) { $ghUser = $ghUser.Trim() }
} catch {}

if (-not [string]::IsNullOrWhiteSpace($ghUser)) {
    Write-Host "Logged in as GitHub user: $ghUser" -ForegroundColor Green
    $remoteUrl = "https://github.com/$ghUser/$repoName.git"

    # Check if repo exists; if not, create it
    gh repo view "$ghUser/$repoName" *> $null
    if ($LASTEXITCODE -ne 0) {
        Write-Host "Creating public repository '$repoName' on GitHub..." -ForegroundColor Yellow
        gh repo create $repoName --public
    }

    git remote remove origin 2>$null
    git remote add origin $remoteUrl

    Write-Host "[5/5] Pushing to GitHub and enabling GitHub Pages..." -ForegroundColor Yellow
    git push -u origin main --force

    # Enable GitHub Pages from main branch root
    gh api -X POST "repos/$ghUser/$repoName/pages" -f "source[branch]=main" -f "source[path]=/" *> $null

    $pagesUrl = "https://$ghUser.github.io/$repoName/"
    Write-Host ""
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host "  DEPLOY COMPLETE!" -ForegroundColor Green
    Write-Host "  URL: $pagesUrl" -ForegroundColor Green
    Write-Host "  (It may take 1-2 minutes to become live)" -ForegroundColor Yellow
    Write-Host "==========================================" -ForegroundColor Green
    Write-Host ""
    Start-Process $pagesUrl
} else {
    Write-Host "GitHub CLI is not logged in. Please enter your GitHub repository URL," -ForegroundColor Yellow
    Write-Host "or press Enter to log in with GitHub in your browser." -ForegroundColor Yellow
    $inputUrl = Read-Host "Repository URL (or press Enter to login)"
    if ([string]::IsNullOrWhiteSpace($inputUrl)) {
        gh auth login --web -p https -h github.com
        $ghUser = (gh api user --jq .login 2>$null)
        if ($ghUser) {
            $ghUser = $ghUser.Trim()
            gh repo view "$ghUser/$repoName" *> $null
            if ($LASTEXITCODE -ne 0) {
                gh repo create $repoName --public
            }
            $remoteUrl = "https://github.com/$ghUser/$repoName.git"
            git remote remove origin 2>$null
            git remote add origin $remoteUrl
            git push -u origin main --force
            gh api -X POST "repos/$ghUser/$repoName/pages" -f "source[branch]=main" -f "source[path]=/" *> $null
            $pagesUrl = "https://$ghUser.github.io/$repoName/"
            Write-Host "DEPLOY COMPLETE! URL: $pagesUrl" -ForegroundColor Green
            Start-Process $pagesUrl
        }
    } else {
        git remote remove origin 2>$null
        git remote add origin $inputUrl.Trim()
        git push -u origin main --force
        Write-Host "Pushed to $inputUrl! Enable GitHub Pages in Repository Settings -> Pages -> Branch: main." -ForegroundColor Green
    }
}

Write-Host ""
Read-Host "Press Enter to close this window"

