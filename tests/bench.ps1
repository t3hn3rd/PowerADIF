<#
.SYNOPSIS
    Benchmarks PowerADIF import performance.

.DESCRIPTION
    Imports a test ADIF file using PowerADIF and reports the elapsed time,
    record count, and error count. Useful for measuring the impact of
    parser optimizations.

.PARAMETER Path
    Path to an ADIF file to import. Defaults to the test file shipped
    with this repository (ADIF_315_test_QSOs_2024_11_28.adi).

.PARAMETER Iterations
    Number of import iterations to run. When greater than 1 the script
    reports the average time across all runs. Defaults to 1.

.EXAMPLE
    .\bench.ps1

.EXAMPLE
    .\bench.ps1 -Path .\my_log.adi -Iterations 3
#>
[CmdletBinding()]
param(
    [Parameter()]
    [string]$Path,

    [Parameter()]
    [ValidateRange(1, 100)]
    [int]$Iterations = 1
)

$ErrorActionPreference = 'Stop'

# Resolve paths relative to the repo root
$RepoRoot   = Split-Path -Parent $PSScriptRoot
$ModulePath  = Join-Path $RepoRoot 'PowerADIF' 'PowerADIF.psd1'

if (-not $Path) {
    $Path = Join-Path $PSScriptRoot 'ADIF_315_test_QSOs_2024_11_28.adi'
}

if (-not (Test-Path $ModulePath)) {
    Write-Error "Module manifest not found at $ModulePath"
    return
}
if (-not (Test-Path $Path)) {
    Write-Error "ADIF test file not found at $Path"
    return
}

Import-Module $ModulePath -Force

$timings = [System.Collections.Generic.List[double]]::new()

for ($i = 1; $i -le $Iterations; $i++) {
    $elapsed = Measure-Command {
        $result = Import-ADIF -Path $Path
    }
    $timings.Add($elapsed.TotalSeconds)

    if ($Iterations -gt 1) {
        Write-Host "  Run ${i}: $([math]::Round($elapsed.TotalSeconds, 3))s"
    }
}

$avg = ($timings | Measure-Object -Average).Average

Write-Host ''
Write-Host "File:       $(Split-Path $Path -Leaf)"
Write-Host "Records:    $($result.Records.Count)"
Write-Host "Errors:     $($result.Errors.Count)"
if ($Iterations -gt 1) {
    Write-Host "Iterations: $Iterations"
    Write-Host "Average:    $([math]::Round($avg, 3))s"
} else {
    Write-Host "Time:       $([math]::Round($avg, 3))s"
}
