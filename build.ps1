# Build script for ascii_center workspace
# Compiles shared UI types first, then builds the Vite bundle
#
# Usage:
#   .\build.ps1           - Build only (no deployment)
#   .\build.ps1 -Deploy 1 - Build and deploy to Home Assistant

param(
    [int]$Deploy = 0
)

Write-Host "Building ascii_center workspace..." -ForegroundColor Cyan
Write-Host ""

# Step 1: Compile shared UI TypeScript declarations
Write-Host "Step 1: Compiling @ascii/shared-ui types..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\packages\ascii_shared_ui"
$output = pnpm exec tsc -p tsconfig.json 2>&1

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to compile shared-ui types" -ForegroundColor Red
    Write-Host $output
    exit $LASTEXITCODE
}

Write-Host "[OK] Shared UI types compiled" -ForegroundColor Green
Write-Host ""

# Step 2: Build ascii_center Vite bundle
Write-Host "Step 2: Building @ascii/ascii-center bundle..." -ForegroundColor Yellow
Set-Location "$PSScriptRoot\packages\ascii_center"
pnpm build

if ($LASTEXITCODE -ne 0) {
    Write-Host "Failed to build ascii-center" -ForegroundColor Red
    exit $LASTEXITCODE
}

Write-Host "[OK] Ascii Center built" -ForegroundColor Green
Write-Host ""

# Return to workspace root
Set-Location $PSScriptRoot

Write-Host "[OK] Ascii Center built" -ForegroundColor Green
Write-Host ""
Write-Host "=== Build completed successfully! ===" -ForegroundColor Green
Write-Host ""

# Step 3: Deploy to Home Assistant (if requested)
if ($Deploy -eq 1) {
    Write-Host "Step 3: Deploying to Home Assistant..." -ForegroundColor Yellow
    $sourceDir = "$PSScriptRoot\packages\ascii_center\dist"
    $targetDir = "\\192.168.1.4\config\www\ascii"

    try {
        # Test if network path is accessible
        if (Test-Path $targetDir) {
            # Copy all files from dist to target
            Copy-Item -Path "$sourceDir\*" -Destination $targetDir -Recurse -Force -ErrorAction Stop
            Write-Host "[OK] Files deployed to $targetDir" -ForegroundColor Green
            Write-Host "    - ascii-center.js (HA bundle)" -ForegroundColor Gray
            Write-Host "    - index.html (dev preview)" -ForegroundColor Gray
            Write-Host "    - assets/ (dev assets)" -ForegroundColor Gray
        } else {
            Write-Host "[SKIP] Network path not accessible: $targetDir" -ForegroundColor Yellow
            Write-Host "       Please manually copy: packages\ascii_center\dist\* -> $targetDir" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "[SKIP] Could not deploy to Home Assistant: $($_.Exception.Message)" -ForegroundColor Yellow
        Write-Host "       Please manually copy: packages\ascii_center\dist\* -> $targetDir" -ForegroundColor Yellow
    }

    Write-Host ""
    Write-Host "Done! Remember to bump cache version (?v=X) in HA panel loader." -ForegroundColor Cyan
} else {
    Write-Host "To deploy, copy: packages\ascii_center\dist\* -> \\192.168.1.4\config\www\ascii" -ForegroundColor Cyan
    Write-Host "Or run: .\build.ps1 -Deploy 1" -ForegroundColor Cyan
}
