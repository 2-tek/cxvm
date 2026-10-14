# 2-TEK Cex Dispatcher (Delegates to cxvm.ps1)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths)
param([Parameter(ValueFromRemainingArguments = $true)]$Args)
$BinDir = $PSScriptRoot
& (Join-Path $BinDir "cxvm.ps1") @Args
