# Pocket CLI Installer for Windows
# Usage: irm https://raw.githubusercontent.com/Gahroot/agent-cli/main/scripts/install.ps1 | iex

$Repo = "Gahroot/agent-cli"
$BinaryName = "pocket.exe"
$InstallDir = "$env:LOCALAPPDATA\Pocket"

# Don't exit on error - handle manually
$ErrorActionPreference = "Continue"

function Write-Info { param($msg) Write-Host "[INFO] $msg" -ForegroundColor Green }
function Write-Warn { param($msg) Write-Host "[WARN] $msg" -ForegroundColor Yellow }
function Write-Err  { param($msg) Write-Host "[ERROR] $msg" -ForegroundColor Red }

# Platform detection
function Get-Platform {
    $arch = $env:PROCESSOR_ARCHITECTURE
    if ($env:PROCESSOR_ARCHITEW6432) { $arch = $env:PROCESSOR_ARCHITEW6432 }

    switch ($arch) {
        "AMD64" { return "windows_amd64" }
        default {
            Write-Err "Unsupported architecture: $arch"
            throw "Unsupported architecture"
        }
    }
}

# Get latest version from GitHub
function Get-LatestVersion {
    Write-Info "Fetching latest version..."
    try {
        $release = Invoke-RestMethod -Uri "https://api.github.com/repos/$Repo/releases/latest" -ErrorAction Stop
        $version = $release.tag_name
        if (-not $version) { throw "No version found" }
        Write-Info "Latest version: $version"
        return $version
    } catch {
        Write-Err "Failed to fetch version: $($_.Exception.Message)"
        throw
    }
}

# Download and install
function Install-Pocket {
    param($Version, $Platform)

    $downloadUrl = "https://github.com/$Repo/releases/download/$Version/pocket_${Platform}.zip"
    Write-Info "Downloading from: $downloadUrl"

    $tmpDir = Join-Path $env:TEMP ([System.IO.Path]::GetRandomFileName())
    New-Item -ItemType Directory -Path $tmpDir -Force | Out-Null

    try {
        $zipPath = Join-Path $tmpDir "pocket.zip"

        # Download with progress disabled for speed
        $prevProgress = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            Invoke-WebRequest -Uri $downloadUrl -OutFile $zipPath -UseBasicParsing -ErrorAction Stop
        } finally {
            $ProgressPreference = $prevProgress
        }

        Write-Info "Extracting..."
        Expand-Archive -Path $zipPath -DestinationPath $tmpDir -Force

        if (-not (Test-Path $InstallDir)) {
            New-Item -ItemType Directory -Path $InstallDir -Force | Out-Null
        }

        $src = Join-Path $tmpDir $BinaryName
        $dest = Join-Path $InstallDir $BinaryName
        Move-Item -Path $src -Destination $dest -Force

        Write-Info "Installed to: $dest"
    } catch {
        Write-Err "Download failed: $($_.Exception.Message)"
        throw
    } finally {
        Remove-Item -Path $tmpDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# Add to PATH
function Add-ToPath {
    $path = [Environment]::GetEnvironmentVariable("PATH", "User")

    if ($path -like "*$InstallDir*") {
        Write-Info "PATH already configured"
        return
    }

    Write-Info "Adding to PATH..."
    [Environment]::SetEnvironmentVariable("PATH", "$path;$InstallDir", "User")
    $env:PATH = "$InstallDir;$env:PATH"
    Write-Info "PATH updated"
}

# Main execution with error wrapper
try {
    Write-Host ""
    Write-Host "+===========================================+" -ForegroundColor Cyan
    Write-Host "|        Pocket CLI Installer              |" -ForegroundColor Cyan
    Write-Host "+===========================================+" -ForegroundColor Cyan
    Write-Host ""

    # Enable TLS 1.2
    [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls12

    $platform = Get-Platform
    Write-Info "Detected platform: $platform"

    $version = Get-LatestVersion
    Install-Pocket -Version $version -Platform $platform
    Add-ToPath

    Write-Host ""
    Write-Host "============================================" -ForegroundColor Green
    Write-Host "  Pocket CLI installed successfully!" -ForegroundColor Green
    Write-Host "============================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Close this terminal and open a new one, then run:" -ForegroundColor White
    Write-Host "  pocket commands" -ForegroundColor Yellow
    Write-Host ""

} catch {
    Write-Host ""
    Write-Host "============================================" -ForegroundColor Red
    Write-Host "  INSTALLATION FAILED" -ForegroundColor Red
    Write-Host "============================================" -ForegroundColor Red
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host ""
}

Write-Host "Press any key to exit..."
$null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
