@echo off
rem 2-TEK Cex Dispatcher (Delegates to cxvm.cmd)
rem Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
setlocal
set "BIN_DIR=%~dp0"
call "%BIN_DIR%cxvm.cmd" %*
