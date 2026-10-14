@echo off
setlocal
set "BIN_DIR=%~dp0"
set "CXVM_DIR=%USERPROFILE%\.cxvm"
if exist "%CXVM_DIR%\bin\cxvm.cmd" (
  call "%CXVM_DIR%\bin\cxvm.cmd" %*
) else (
  bash "%BIN_DIR%cxvm" %*
)
