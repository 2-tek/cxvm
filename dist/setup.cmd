@echo off
rem ==============================================================================
rem 2-TEK Cex Factory: Windows Command Prompt CXVM Setup Launcher
rem Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
rem ==============================================================================
setlocal
set "SCRIPT_DIR=%~dp0"
if exist "%SCRIPT_DIR%setup.ps1" (
  powershell -NoProfile -ExecutionPolicy Bypass -File "%SCRIPT_DIR%setup.ps1" %*
) else (
  echo Error: setup.ps1 not found in %SCRIPT_DIR%
  exit /b 1
)
