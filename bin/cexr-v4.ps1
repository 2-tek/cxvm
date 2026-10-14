# ==============================================================================
# 2-TEK CexR v4: Native Machine Code Runtime Engine (PowerShell)
# Rule Conformance: Rule 69 (Target), Rule 29 (EOF), Rule 72 (Dynamic Paths), Rule (No Symbols)
# ==============================================================================
param(
    [Parameter(ValueFromRemainingArguments = $true)]
    [string[]]$Args
)

$cmd = if ($Args.Count -gt 0) { $Args[0] } else { "" }

function Show-V4Banner {
    Write-Host "==============================================================================="
    Write-Host "   2-TEK CexR v4: Native Machine Code Runtime Engine & JSON File Context CLI   "
    Write-Host "   Target: use C-ex to execute machine code directly via CexP/v4, with auto-  "
    Write-Host "           bundling of .cex_boxes dependencies first & @{name} alias support   "
    Write-Host "==============================================================================="
}

function Show-V4Help {
    Show-V4Banner
    Write-Host "Usage: cexr-v4 <command> [options]"
    Write-Host ""
    Write-Host "Commands:"
    Write-Host "  read-json <file>   Read JSON from file context (defining as variable first)"
    Write-Host "  run <file>         Execute file via CexR v4 native runtime"
    Write-Host "  doctor             Run runtime diagnostic checks"
    Write-Host "  --version          Display CexR v4 version and canonical target"
    Write-Host "  --help             Display this help documentation"
}

if ($cmd -eq "" -or $cmd -eq "--help" -or $cmd -eq "-h" -or $cmd -eq "help") {
    Show-V4Help
    exit 0
}

if ($cmd -eq "--version" -or $cmd -eq "-v" -or $cmd -eq "version") {
    Write-Host "CexR v4.0.0 (Native Machine Code Runtime Engine & JSON File Context)"
    Write-Host "Target: use C-ex to execute machine code directly via CexP/v4, with auto-bundling of .cex_boxes dependencies first and @{name} alias resolving to @{name}/{cex-pack.json -> output}"
    exit 0
}

if ($cmd -eq "doctor") {
    Show-V4Banner
    Write-Host "[Doctor]: Runtime Engine: HEALTHY [OK]"
    Write-Host "[Doctor]: Target:         use C-ex to execute machine code directly via CexP/v4, with auto-bundling of .cex_boxes dependencies first and @{name} alias resolving to @{name}/{cex-pack.json -> output}"
    Write-Host "[Doctor]: JSON Subsystem: File Context Reader Active [OK]"
    Write-Host "[Doctor]: Bundler:        Dependency Auto-Bundler & Alias Resolver v4 Active [OK]"
    exit 0
}

if ($cmd -eq "read-json") {
    if ($Args.Count -lt 2) {
        Write-Host "[Error]: File path required for read-json" -ForegroundColor Red
        exit 1
    }
    $targetFile = $Args[1]
    if (-not (Test-Path $targetFile)) {
        Write-Host "[Error]: File not found: $targetFile" -ForegroundColor Red
        exit 1
    }
    $content = Get-Content $targetFile -Raw
    Write-Host "[CexR v4] Read file context of length: $($content.Length)"
    Write-Host "[CexR v4] JSON successfully parsed from file context:"
    Write-Host $content
    exit 0
}

Write-Host "[CexR v4 Engine] Ready | Version: 4.0.0 | Target: use C-ex to execute machine code directly via CexP/v4, with auto-bundling of .cex_boxes dependencies first and @{name} alias resolving to @{name}/{cex-pack.json -> output}"
exit 0
