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
$CovData  = Join-Path $BuildDir 'coverage.dat'
$CovLog   = Join-Path $LogDir 'coverage.log'

$UcrtBin   = Join-Path $Msys2Root 'ucrt64\bin'
$UsrBin    = Join-Path $Msys2Root 'usr\bin'
$Verilator = Join-Path $UcrtBin 'verilator_bin.exe'
# The Perl-free binary behind the verilator_coverage wrapper.
$VerilatorCov = Join-Path $UcrtBin 'verilator_coverage_bin_dbg.exe'

function Fail([string]$Message) {
    Write-Host "sim.ps1: $Message" -ForegroundColor Red
    exit 1
}

function Initialize-Environment {
    if (-not (Test-Path $Verilator)) { Fail "Verilator not found at $Verilator" }
    # The built-in default (/ucrt64/share/verilator) only resolves inside an MSYS2 shell.
    $env:VERILATOR_ROOT = ($Msys2Root -replace '\\', '/') + '/ucrt64/share/verilator'
    # usr\bin first: the generated C++ is compiled with the MSYS (Cygwin-runtime) g++,
    # because Verilator only enables constraint solving where fork() exists, which the
    # native UCRT64 g++ does not provide. make and its POSIX shell also live there.
    # ucrt64\bin: python3 and the z3 solver.
    $env:Path = "$UsrBin;$UcrtBin;$env:Path"
    # Solver for randomize() with constraints, reached through the bridge built by
    # Build-SolverBridge. Verilator splits this on spaces, so no path in it may contain
    # one; the bridge path is relative to build/, where the simulation runs.
    $env:VERILATOR_SOLVER = './z3_bridge.exe ' + ($Msys2Root -replace '\\', '/') + '/ucrt64/bin/z3.exe --in'
}

# Compiles scripts/z3_bridge.c into build/ when missing or older than its source.
# It must be built with the MSYS gcc; see the comment at the top of the source.
function Build-SolverBridge {
    $src = Join-Path $PSScriptRoot 'z3_bridge.c'
    $exe = Join-Path $BuildDir 'z3_bridge.exe'
    if ((Test-Path $exe) -and ((Get-Item $exe).LastWriteTime -ge (Get-Item $src).LastWriteTime)) { return }
    Write-Host '-- BRIDGE: gcc scripts/z3_bridge.c -> build/z3_bridge.exe'
    & (Join-Path $UsrBin 'gcc.exe') -O2 -Wall -o 'build/z3_bridge.exe' 'scripts/z3_bridge.c' -lpthread
    if ($LASTEXITCODE -ne 0) { Fail 'Could not compile scripts/z3_bridge.c' }
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
    Build-SolverBridge
    # --coverage: code coverage and covergroup bins, written to build/coverage.dat at the end of the run.
    $vargs = @('--binary', '-j', '0', '-Mdir', $ObjDir, '-o', $SimName, '--coverage')
    if ($Trace) {
        $vargs += '--trace-vcd'
        if ($TraceDepth -gt 0) { $vargs += @('--trace-depth', "$TraceDepth") }
    }
    $vargs += Get-CommonArgs
    Write-Host "-- BUILD: verilator_bin $($vargs -join ' ')"
    & $Verilator @vargs
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
}

# Writes logs/coverage.log: the summary from verilator_coverage, then one line per
# covergroup bin (the tool has no per-bin listing), bins never hit first.
function Write-CoverageReport {
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $out = New-Object System.Collections.Generic.List[string]
    if (Test-Path $VerilatorCov) {
        $ErrorActionPreference = 'Continue'
        & $VerilatorCov $CovData 2>&1 | ForEach-Object { "$_" } |
            Where-Object { $_ -notmatch 'shared_info::initialize' } | ForEach-Object { $out.Add($_) }
        $ErrorActionPreference = 'Stop'
    }
    else {
        $out.Add("verilator_coverage not found at $VerilatorCov, summary skipped")
    }

    # Data lines look like: C '<fields>' <count>, where every field is 0x01 key 0x02 value.
    # Key "t" is the coverage type and "h" is group.coverpoint.bin for covergroup entries.
    $bins = @()
    foreach ($line in [System.IO.File]::ReadAllLines($CovData)) {
        if ($line -notmatch "^C '(.*)' (\d+)$") { continue }
        $count = [long]$Matches[2]
        $fields = @{}
        foreach ($field in ($Matches[1] -split [char]1)) {
            $kv = $field -split [char]2, 2
            if ($kv.Count -eq 2) { $fields[$kv[0]] = $kv[1] }
        }
        if ($fields['t'] -ne 'covergroup') { continue }
        $name = "$($fields['h'])" -replace '^__vlAnonCG_', ''
        $cut = $name.LastIndexOf('.')
        if ($cut -lt 0) { continue }
        $bins += [pscustomobject]@{ Point = $name.Substring(0, $cut); Bin = $name.Substring($cut + 1); Hits = $count; Kind = "$($fields['bin_type'])" }
    }
    # ignore_bins and illegal_bins are in the database too, and the tool's summary above
    # counts them as ordinary bins. They are listed here but kept out of the totals.
    $counted = @($bins | Where-Object { $_.Kind -notin 'ignore', 'illegal' })

    $out.Add('')
    if ($bins.Count -eq 0) {
        $out.Add('Covergroup bins: none found')
    }
    else {
        $hit = @($counted | Where-Object { $_.Hits -gt 0 }).Count
        $excluded = $bins.Count - $counted.Count
        $note = if ($excluded -gt 0) { " ($excluded ignore/illegal bins not counted)" } else { '' }
        $out.Add("Covergroup bins: $hit of $($counted.Count) hit$note")
        foreach ($point in ($bins | Group-Object Point | Sort-Object Name)) {
            $pointBins = @($point.Group | Where-Object { $_.Kind -notin 'ignore', 'illegal' })
            $pointHit = @($pointBins | Where-Object { $_.Hits -gt 0 }).Count
            $out.Add('')
            $out.Add("$($point.Name)  ($pointHit of $($pointBins.Count))")
            $width = ($point.Group | ForEach-Object { $_.Bin.Length } | Measure-Object -Maximum).Maximum
            # Order: missed bins, hit bins, then the excluded ones.
            $order = { if ($_.Kind -in 'ignore', 'illegal') { 2 } elseif ($_.Hits -gt 0) { 1 } else { 0 } }
            foreach ($b in ($point.Group | Sort-Object @{ Expression = $order }, Bin)) {
                $mark = if ($b.Kind -in 'ignore', 'illegal') { $b.Kind.ToUpper() } elseif ($b.Hits -eq 0) { 'MISS' } else { '' }
                $out.Add(('  {0}  {1}  {2,8}' -f $mark.PadRight(7), $b.Bin.PadRight($width), $b.Hits))
            }
        }
    }
    [System.IO.File]::WriteAllLines($CovLog, $out, $utf8)
    Write-Host "-- COVERAGE: $CovLog"
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
    $cov = Get-Item $CovData -ErrorAction SilentlyContinue
    if ($cov -and $cov.LastWriteTime -ge $start) { Write-CoverageReport }
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
