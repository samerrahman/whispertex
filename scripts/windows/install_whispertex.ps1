# WhisperTeX Windows Setup Script
# Installs requirements and optionally creates a Desktop shortcut

Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host "   WhisperTeX Windows Setup (Speech to LaTeX)          " -ForegroundColor Cyan
Write-Host "=======================================================" -ForegroundColor Cyan
Write-Host ""

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue
if (-not $pythonCmd) {
    Write-Host "[ERROR] Python was not found in your PATH." -ForegroundColor Red
    Write-Host "Please download Python 3.9+ from https://www.python.org/downloads/ and check 'Add Python to PATH'." -ForegroundColor Yellow
    Exit 1
}

Write-Host "Installing Python dependencies (requests, pynput)..." -ForegroundColor Green
& python -m pip install -q requests pynput

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$batPath = Join-Path $scriptDir "run_whispertex.bat"

# Create Desktop Shortcut
$desktop = [Environment]::GetFolderPath("Desktop")
$shortcutPath = Join-Path $desktop "WhisperTeX.lnk"

try {
    $WshShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($shortcutPath)
    $Shortcut.TargetPath = $batPath
    $Shortcut.WorkingDirectory = $scriptDir
    $Shortcut.Description = "WhisperTeX — Speech to LaTeX"
    $Shortcut.Save()
    Write-Host "Created Desktop shortcut: $shortcutPath" -ForegroundColor Green
} catch {
    Write-Host "Note: Could not automatically create Desktop shortcut." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Setup complete!" -ForegroundColor Cyan
Write-Host "Double-click 'run_whispertex.bat' or the Desktop shortcut to start." -ForegroundColor Cyan
Write-Host "Global Hotkey: Ctrl+Alt+L" -ForegroundColor Yellow
Write-Host ""
