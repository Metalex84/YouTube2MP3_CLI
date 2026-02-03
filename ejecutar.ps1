# ================================================================================
# EJECUTOR - YouTube to MP3 Converter (Docker)
# ================================================================================
# Single-entry script that runs the CLI inside Docker.
# Requires: Docker Desktop (or docker engine) installed and running.
# ================================================================================

param(
    [Parameter(Position=0, ValueFromRemainingArguments=$true)]
    [string[]]$Arguments
)

function Write-ColorOutput([string]$Message, [string]$Color = "White") {
    switch ($Color) {
        "Green" { Write-Host $Message -ForegroundColor Green }
        "Red" { Write-Host $Message -ForegroundColor Red }
        "Yellow" { Write-Host $Message -ForegroundColor Yellow }
        "Cyan" { Write-Host $Message -ForegroundColor Cyan }
        default { Write-Host $Message }
    }
}

function Write-Error-Custom([string]$Message) {
    Write-ColorOutput "[ERROR] $Message" "Red"
}

function Write-Info([string]$Message) {
    Write-ColorOutput "[INFO] $Message" "Cyan"
}

function Write-Warn([string]$Message) {
    Write-ColorOutput "[WARNING] $Message" "Yellow"
}

# Ensure we are in the project directory
if (-not (Test-Path (Join-Path $PSScriptRoot "descargar_audio.py"))) {
    Write-Error-Custom "This script must be run from the project directory."
    Write-Info "Expected to find descargar_audio.py next to this script."
    exit 1
}

# Check Docker availability
try {
    $null = docker --version
}
catch {
    Write-Error-Custom "Docker is not installed or not available in PATH."
    Write-Info "Install Docker Desktop and try again."
    exit 1
}

# Directories
$downloadsDir = Join-Path $PSScriptRoot "downloads"
$logsDir = Join-Path $PSScriptRoot "logs"

if (-not (Test-Path $downloadsDir)) {
    New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
    Write-Info "Created downloads directory: $downloadsDir"
}

if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    Write-Info "Created logs directory: $logsDir"
}

# Docker image
$imageName = "y2m-cli"
$imageExists = docker images -q $imageName

if (-not $imageExists) {
    Write-Info "Building Docker image..."
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Error-Custom "Docker image build failed."
        exit 1
    }
    Write-Info "Docker image built successfully."
}

# Argument processing
$scriptArgs = @()
$inputMount = $null
$outputMount = $null
$foundOutputArg = $false
$csvProvided = $false
$allowNoCsv = $false

for ($i = 0; $i -lt $Arguments.Count; $i++) {
    $arg = $Arguments[$i]

    if ($arg -eq "-h" -or $arg -eq "--help" -or $arg -eq "--version") {
        $allowNoCsv = $true
        $scriptArgs += $arg
        continue
    }

    if ($arg -eq "-o" -or $arg -eq "--output-dir") {
        if ($i + 1 -ge $Arguments.Count) {
            Write-Error-Custom "Missing value for -o/--output-dir."
            exit 1
        }

        $outRaw = $Arguments[$i + 1]
        $outPath = Resolve-Path -Path $outRaw -ErrorAction SilentlyContinue
        if (-not $outPath) {
            $outPath = Join-Path $PSScriptRoot $outRaw
        }

        # Ensure output directory exists
        if (-not (Test-Path $outPath)) {
            New-Item -ItemType Directory -Path $outPath -Force | Out-Null
        }

        $outputMount = (Resolve-Path -Path $outPath).Path
        $foundOutputArg = $true

        $scriptArgs += $arg
        $scriptArgs += "/app/output"
        $i++
        continue
    }

    if ($arg.StartsWith("-")) {
        $scriptArgs += $arg
        continue
    }

    if ($csvProvided) {
        Write-Error-Custom "Only one CSV file is allowed."
        exit 1
    }

    $csvRaw = $arg
    $csvPath = Resolve-Path -Path $csvRaw -ErrorAction SilentlyContinue
    if (-not $csvPath) {
        $csvPath = Resolve-Path -Path (Join-Path $PSScriptRoot $csvRaw) -ErrorAction SilentlyContinue
    }
    if (-not $csvPath) {
        Write-Error-Custom "CSV file not found: $csvRaw"
        exit 1
    }

    $csvDir = Split-Path -Path $csvPath -Parent
    $csvFile = Split-Path -Path $csvPath -Leaf

    if ($inputMount -and ($inputMount -ne $csvDir)) {
        Write-Error-Custom "Only one CSV directory can be mounted per run."
        Write-Info "Place all CSV files in the same folder and try again."
        exit 1
    }

    $inputMount = $csvDir
    $scriptArgs += ("/app/input/" + $csvFile)
    $csvProvided = $true
}

if (-not $csvProvided -and -not $allowNoCsv) {
    Write-Error-Custom "Missing CSV file. Usage: .\\ejecutar.ps1 <urls.csv> [-o <output-dir>]"
    exit 1
}

# If no output dir provided, force container output to /app/downloads
if (-not $foundOutputArg) {
    $scriptArgs += "-o"
    $scriptArgs += "/app/downloads"
}

# Docker run arguments
$runArgs = @(
    "--rm",
    "-it",
    "-v", "${downloadsDir}:/app/downloads",
    "-v", "${logsDir}:/app/logs"
)

if ($inputMount) {
    $runArgs += "-v"
    $runArgs += "${inputMount}:/app/input:ro"
}

if ($outputMount -and ($outputMount -ne $downloadsDir)) {
    $runArgs += "-v"
    $runArgs += "${outputMount}:/app/output"
}

$runArgs += $imageName
$runArgs += $scriptArgs

Write-Info "Running CLI in Docker..."
Write-Host "[INFO] Args: $($scriptArgs -join ' ')" -ForegroundColor Gray

& docker run @runArgs
$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-ColorOutput "[OK] Completed successfully." "Green"
    Write-Info "Downloads: $downloadsDir"
    Write-Info "Logs: $logsDir"
} else {
    Write-Warn "Process finished with exit code: $exitCode"
}

exit $exitCode
