# Komari Build Script for Shared Hosting (PowerShell)
# Builds index.fcgi for shared hosting environments like Netcup

Write-Host "Building Komari for shared hosting..." -ForegroundColor Green
Write-Host ""

# Set build parameters
$env:GOOS = "linux"
$env:GOARCH = "amd64"
$env:CGO_ENABLED = "0"

# Get version information
try {
    $VERSION = git describe --tags --always 2>$null
    if (-not $VERSION) { $VERSION = "production" }
} catch {
    $VERSION = "production"
}

try {
    $COMMIT_HASH = git rev-parse --short HEAD 2>$null
    if (-not $COMMIT_HASH) { $COMMIT_HASH = "unknown" }
} catch {
    $COMMIT_HASH = "fcgi local version"
}

Write-Host "Version: $VERSION" -ForegroundColor Cyan
Write-Host "Commit: $COMMIT_HASH" -ForegroundColor Cyan
Write-Host ""

# Build
Write-Host "Compiling..." -ForegroundColor Yellow
$LDFLAGS = "-s -w -X github.com/komari-monitor/komari/internal/conf.Version=$VERSION -X github.com/komari-monitor/komari/internal/conf.CommitHash=$COMMIT_HASH"
go build -o index.fcgi -ldflags="$LDFLAGS" .

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "Build successful!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Generated file:" -ForegroundColor Cyan
    Get-Item index.fcgi | Format-Table Name, Length, LastWriteTime
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "1. Rename .htaccess.direct to .htaccess"
    Write-Host "2. Upload index.fcgi and .htaccess to your server"
    Write-Host "3. Set permissions: chmod 755 index.fcgi"
    Write-Host "4. Access your domain to test"
    Write-Host ""
    Write-Host "Tip: Edit SetEnv section in .htaccess if you need to configure database" -ForegroundColor Magenta
} else {
    Write-Host ""
    Write-Host "Build failed!" -ForegroundColor Red
    exit 1
}
