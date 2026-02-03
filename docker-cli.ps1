# Script para ejecutar el CLI de YouTube to MP3 en contenedor Docker
# Uso: .\docker-cli.ps1 [argumentos del script Python]

# Crear directorios si no existen
$downloadsDir = Join-Path $PSScriptRoot "downloads"
$logsDir = Join-Path $PSScriptRoot "logs"

if (-not (Test-Path $downloadsDir)) {
    New-Item -ItemType Directory -Path $downloadsDir -Force | Out-Null
    Write-Host "[INFO] Directorio de descargas creado: $downloadsDir" -ForegroundColor Green
}

if (-not (Test-Path $logsDir)) {
    New-Item -ItemType Directory -Path $logsDir -Force | Out-Null
    Write-Host "[INFO] Directorio de logs creado: $logsDir" -ForegroundColor Green
}

# Construir la imagen si no existe
$imageName = "y2m-app"
$imageExists = docker images -q $imageName

if (-not $imageExists) {
    Write-Host "[INFO] Construyendo imagen Docker..." -ForegroundColor Yellow
    docker build -t $imageName .
    if ($LASTEXITCODE -ne 0) {
        Write-Host "[ERROR] Fallo al construir la imagen Docker" -ForegroundColor Red
        exit 1
    }
    Write-Host "[SUCCESS] Imagen Docker construida correctamente" -ForegroundColor Green
}

# Obtener los argumentos pasados al script
$scriptArgs = @()
foreach ($arg in $args) {
    # Si el argumento es --csv-file, convertir la ruta del siguiente argumento
    if ($arg -eq "--csv-file") {
        $scriptArgs += $arg
    }
    elseif ($scriptArgs[-1] -eq "--csv-file" -and -not $arg.StartsWith("/")) {
        # Convertir ruta local a ruta del contenedor
        $scriptArgs += "/app/input/$arg"
    }
    else {
        $scriptArgs += $arg
    }
}

$scriptArgsString = $scriptArgs -join " "

# Si no se pasan argumentos, mostrar ayuda
if ([string]::IsNullOrWhiteSpace($scriptArgsString)) {
    Write-Host "`n=== YouTube to MP3 Downloader - Docker CLI ===" -ForegroundColor Cyan
    Write-Host "`nEjemplos de uso:" -ForegroundColor Yellow
    Write-Host "  .\docker-cli.ps1 --help" -ForegroundColor White
    Write-Host "  .\docker-cli.ps1 `"https://www.youtube.com/watch?v=VIDEO_ID`"" -ForegroundColor White
    Write-Host "  .\docker-cli.ps1 --csv-file test_urls.csv" -ForegroundColor White
    Write-Host "  .\docker-cli.ps1 --csv-file test_urls.csv -o /app/downloads" -ForegroundColor White
    Write-Host "`nNota: Los archivos CSV deben estar en el directorio del proyecto" -ForegroundColor Yellow
    Write-Host "      Los archivos se guardarán en: $downloadsDir" -ForegroundColor Green
    Write-Host "      Los logs se guardarán en: $logsDir`n" -ForegroundColor Green
    
    # Mostrar ayuda del script
    docker run --rm `
        -v "${downloadsDir}:/app/downloads" `
        -v "${logsDir}:/app/logs" `
        -v "${PSScriptRoot}:/app/input:ro" `
        $imageName python descargar_audio.py --help
    exit 0
}

Write-Host "`n[START] Ejecutando CLI en contenedor Docker..." -ForegroundColor Cyan
Write-Host "[INFO] Argumentos: $scriptArgsString`n" -ForegroundColor Gray

# Ejecutar el contenedor con los argumentos proporcionados
# Montar directorios para descargas, logs y archivos de entrada (CSV)
docker run --rm -it `
    -v "${downloadsDir}:/app/downloads" `
    -v "${logsDir}:/app/logs" `
    -v "${PSScriptRoot}:/app/input:ro" `
    $imageName python descargar_audio.py $scriptArgsString

$exitCode = $LASTEXITCODE

if ($exitCode -eq 0) {
    Write-Host "`n[SUCCESS] Proceso completado" -ForegroundColor Green
    Write-Host "[INFO] Archivos descargados en: $downloadsDir" -ForegroundColor Cyan
    Write-Host "[INFO] Logs guardados en: $logsDir`n" -ForegroundColor Cyan
} else {
    Write-Host "`n[ERROR] El proceso terminó con código de error: $exitCode" -ForegroundColor Red
}

exit $exitCode
