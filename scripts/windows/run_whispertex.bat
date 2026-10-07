@echo off
setlocal enabledelayedexpansion
title WhisperTeX — Speech to LaTeX for Windows

echo =======================================================
echo          WhisperTeX for Windows (Speech to LaTeX)
echo =======================================================
echo.

where python >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Python 3 is not found in your PATH.
    echo Please install Python 3.9+ from https://www.python.org/downloads/
    echo Make sure to check "Add Python to PATH" during installation.
    echo.
    pause
    exit /b 1
)

if "%GROQ_API_KEY%"=="" if "%OPENAI_API_KEY%"=="" if "%GEMINI_API_KEY%"=="" (
    echo No API key detected in environment.
    set /p USER_GROQ="Enter your Groq API Key (free from https://console.groq.com/keys): "
    if not "!USER_GROQ!"=="" (
        set GROQ_API_KEY=!USER_GROQ!
    )
)

echo.
echo Checking dependencies...
python -c "import requests, pynput" >nul 2>nul
if %ERRORLEVEL% NEQ 0 (
    echo Installing required packages (requests, pynput)...
    python -m pip install -q requests pynput
)

echo.
echo Starting WhisperTeX Background Push-to-Talk Daemon...
echo Press [Ctrl + Alt + L] anywhere on Windows to dictate math.
echo.
python -m whispertex.cli daemon

pause
