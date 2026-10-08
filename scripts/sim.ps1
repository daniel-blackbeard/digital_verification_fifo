<#
.SYNOPSIS
    Lint, build, run and clean a Verilator simulation without the Perl wrapper.

.DESCRIPTION
    Calls verilator_bin.exe from the MSYS2 UCRT64 install directly. The
    environment (VERILATOR_ROOT and PATH) is changed for this process only.

    Sources come from one or more file lists (default: scripts/files.f). Paths
    inside a file list are relative to the directory of that file list.

.EXAMPLE
    scripts\sim.ps1 lint
    scripts\sim.ps1 build -Top my_tb
    scripts\sim.ps1 run -Top my_tb -Trace
    scripts\sim.ps1 run -FileList scripts/files.f,scripts/other.f -SimArgs '+seed=1'
    scripts\sim.ps1 clean
#>
[CmdletBinding()]
param(
    [Parameter(Position = 0)]
    [ValidateSet('lint', 'build', 'run', 'clean')]
    [string]$Action = 'run',

    # Top module name. If omitted, Verilator infers it.
    [string]$Top = '',

    # File lists, relative to the repository root.
    [string[]]$FileList = @('scripts/files.f'),

    # Compile with waveform tracing support (VCD).
    [switch]$Trace,

    # With -Trace: how many hierarchy levels below the top to trace (0 = all).
    [int]$TraceDepth = 0,

    # Extra arguments passed to Verilator as they are.
    [string[]]$VerilatorArgs = @(),

    # Arguments passed to the simulation executable (plusargs).
    [string[]]$SimArgs = @(),

    [string]$Msys2Root = 'C:\msys64'
)

$ErrorActionPreference = 'Stop'

$RepoRoot = Split-Path -Parent $PSScriptRoot
$BuildDir = Join-Path $RepoRoot 'build'
$ObjDir   = 'build/obj_dir'
$SimName  = 'sim'
$SimExe   = Join-Path $BuildDir "obj_dir\$SimName.exe"
$LogDir   = Join-Path $RepoRoot 'logs'
$SimLog   = Join-Path $LogDir 'sim.log'

$UcrtBin   = Join-Path $Msys2Root 'ucrt64\bin'
$UsrBin    = Join-Path $Msys2Root 'usr\bin'
$Verilator = Join-Path $UcrtBin 'verilator_bin.exe'

function Fail([string]$Message) {
    Write-Host "sim.ps1: $Message" -ForegroundColor Red
    exit 1
}

function Initialize-Environment {
    if (-not (Test-Path $Verilator)) { Fail "Verilator not found at $Verilator" }
    # The built-in default (/ucrt64/share/verilator) only resolves inside an MSYS2 shell.
    $env:VERILATOR_ROOT = ($Msys2Root -replace '\\', '/') + '/ucrt64/share/verilator'
    # ucrt64\bin: g++, python3. usr\bin: make and the POSIX shell it needs.
    $env:Path = "$UcrtBin;$UsrBin;$env:Path"
}

function Get-CommonArgs {
    $list = @()
    # "-File" invocations (VS Code tasks) pass "a.f,b.f" as one string, so split it.
    foreach ($f in ($FileList -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })) {
        $path = $f
        if (-not [System.IO.Path]::IsPathRooted($f)) { $path = Join-Path $RepoRoot $f }
        if (-not (Test-Path $path)) { Fail "File list not found: $f" }
        # -F: paths inside the list are relative to the list's own directory.
        $list += @('-F', ($f -replace '\\', '/'))
    }
    # Verilator configuration files (lint waivers, tracing rules), if present.
    foreach ($vlt in (Get-ChildItem $PSScriptRoot -Filter '*.vlt' | Sort-Object Name)) { $list += "scripts/$($vlt.Name)" }
    if ($Top) { $list += @('--top-module', $Top) }
    $list += @('--assert', '-Wall')
    $list += $VerilatorArgs
    return $list
}

function Invoke-Lint {
    Initialize-Environment
    $vargs = @('--lint-only', '--timing') + (Get-CommonArgs)
    Write-Host "-- LINT: verilator_bin $($vargs -join ' ')"
    & $Verilator @vargs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Invoke-Build {
    Initialize-Environment
    # Verilator creates obj_dir itself but not its parent directory.
    New-Item -ItemType Directory -Force $BuildDir | Out-Null
    $vargs = @('--binary', '-j', '0', '-Mdir', $ObjDir, '-o', $SimName)
    # g++ 16 fails to link the Verilator runtime with the default -Os
    # (undefined reference to the std::string move constructor), so use -O2.
    $vargs += @('-MAKEFLAGS', 'OPT_FAST=-O2', '-MAKEFLAGS', 'OPT_GLOBAL=-O2')
    if ($Trace) {
        $vargs += '--trace-vcd'
        if ($TraceDepth -gt 0) { $vargs += @('--trace-depth', "$TraceDepth") }
    }
    $vargs += Get-CommonArgs
    Write-Host "-- BUILD: verilator_bin $($vargs -join ' ')"
    & $Verilator @vargs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

function Invoke-Run {
    Invoke-Build
    if (-not (Test-Path $SimExe)) { Fail "Simulation executable not found: $SimExe" }
    Write-Host "-- RUN: $SimExe $($SimArgs -join ' ')"
    New-Item -ItemType Directory -Force $LogDir | Out-Null
    $start = Get-Date
    $writer = New-Object System.IO.StreamWriter($SimLog, $false, (New-Object System.Text.UTF8Encoding($false)))
    # Run inside build/ so waveform dumps stay out of the sources.
    Push-Location $BuildDir
    try {
        # Merged stderr lines arrive as error records; do not let them stop the script.
        $ErrorActionPreference = 'Continue'
        & $SimExe @SimArgs 2>&1 | ForEach-Object {
            $line = "$_"
            Write-Host $line
            $writer.WriteLine($line)
        }
        $code = $LASTEXITCODE
    }
    finally {
        $ErrorActionPreference = 'Stop'
        $writer.Dispose()
        Pop-Location
    }
    Write-Host "-- LOG: $SimLog"
    foreach ($w in (Get-ChildItem $BuildDir -File | Where-Object { $_.Extension -in '.vcd', '.fst' -and $_.LastWriteTime -ge $start })) {
        Write-Host "-- WAVES: $($w.FullName)"
    }
    if ($code -ne 0) { exit $code }
}

function Invoke-Clean {
    if (Test-Path $BuildDir) {
        Remove-Item -Recurse -Force $BuildDir -Confirm:$false
        Write-Host "-- CLEAN: removed $BuildDir"
    }
    else {
        Write-Host '-- CLEAN: nothing to remove'
    }
}

# Verilator is run from the repository root so reported paths are repo-relative.
Push-Location $RepoRoot
try {
    switch ($Action) {
        'lint'  { Invoke-Lint }
        'build' { Invoke-Build }
        'run'   { Invoke-Run }
        'clean' { Invoke-Clean }
    }
}
finally {
    Pop-Location
}
