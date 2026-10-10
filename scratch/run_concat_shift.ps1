<#
.SYNOPSIS
    Build and run the unpacked array concatenation reproducer (concat_shift.sv).

.DESCRIPTION
    Standalone: does not use scripts/sim.ps1, the file lists or the waivers.
    Calls verilator_bin.exe from the MSYS2 UCRT64 install directly; the
    environment is changed for this process only. Build output goes to
    scratch/obj_dir (ignored by git).

    The equivalent on a standard install is:
        verilator --binary -j 0 --top-module t concat_shift.sv
        ./obj_dir/Vt

.EXAMPLE
    scratch\run_concat_shift.ps1
#>
[CmdletBinding()]
param(
    [string]$Msys2Root = 'C:\msys64'
)

$ErrorActionPreference = 'Stop'

$UcrtBin   = Join-Path $Msys2Root 'ucrt64\bin'
$UsrBin    = Join-Path $Msys2Root 'usr\bin'
$Verilator = Join-Path $UcrtBin 'verilator_bin.exe'

if (-not (Test-Path $Verilator)) {
    Write-Host "ERROR: Verilator not found at $Verilator" -ForegroundColor Red
    exit 1
}

$env:VERILATOR_ROOT = ($Msys2Root -replace '\\', '/') + '/ucrt64/share/verilator'
$env:Path = "$UsrBin;$UcrtBin;$env:Path"

Push-Location $PSScriptRoot
try {
    Write-Host '-- VERSIONS' -ForegroundColor Cyan
    & $Verilator --version
    & g++ --version | Select-Object -First 1

    Write-Host '-- BUILD' -ForegroundColor Cyan
    & $Verilator --binary -j 0 --top-module t -Mdir obj_dir -o concat_shift concat_shift.sv
    if ($LASTEXITCODE -ne 0) {
        Write-Host "ERROR: build failed (exit code $LASTEXITCODE)" -ForegroundColor Red
        exit $LASTEXITCODE
    }

    Write-Host '-- RUN' -ForegroundColor Cyan
    & (Join-Path $PSScriptRoot 'obj_dir\concat_shift.exe')
    exit $LASTEXITCODE
}
finally {
    Pop-Location
}
