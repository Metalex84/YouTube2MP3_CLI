@echo off
REM Script para ejecutar el CLI de YouTube to MP3 en contenedor Docker
REM Uso: docker-cli.bat [argumentos del script Python]

setlocal enabledelayedexpansion

REM Obtener el directorio del script
set "SCRIPT_DIR=%~dp0"
set "DOWNLOADS_DIR=%SCRIPT_DIR%downloads"
set "LOGS_DIR=%SCRIPT_DIR%logs"
set "IMAGE_NAME=y2m-app"

REM Crear directorios si no existen
if not exist "%DOWNLOADS_DIR%" (
    mkdir "%DOWNLOADS_DIR%"
    echo [INFO] Directorio de descargas creado: %DOWNLOADS_DIR%
)

if not exist "%LOGS_DIR%" (
    mkdir "%LOGS_DIR%"
    echo [INFO] Directorio de logs creado: %LOGS_DIR%
)

REM Verificar si la imagen existe
docker images -q %IMAGE_NAME% >nul 2>&1
if errorlevel 1 (
    echo [INFO] Construyendo imagen Docker...
    docker build -t %IMAGE_NAME% "%SCRIPT_DIR%"
    if errorlevel 1 (
        echo [ERROR] Fallo al construir la imagen Docker
        exit /b 1
    )
    echo [SUCCESS] Imagen Docker construida correctamente
)

REM Si no hay argumentos, mostrar ayuda
if "%~1"=="" (
    echo.
    echo === YouTube to MP3 Downloader - Docker CLI ===
    echo.
    echo Ejemplos de uso:
    echo   docker-cli.bat --help
    echo   docker-cli.bat "https://www.youtube.com/watch?v=VIDEO_ID"
    echo   docker-cli.bat --csv-file /app/input/test_urls.csv
    echo   docker-cli.bat --csv-file /app/input/test_urls.csv -o /app/downloads
    echo.
    echo Nota: Los archivos se guardaran en: %DOWNLOADS_DIR%
    echo       Los logs se guardaran en: %LOGS_DIR%
    echo.
    docker run --rm -v "%DOWNLOADS_DIR%:/app/downloads" -v "%LOGS_DIR%:/app/logs" -v "%SCRIPT_DIR%:/app/input:ro" %IMAGE_NAME% python descargar_audio.py --help
    exit /b 0
)

echo.
echo [START] Ejecutando CLI en contenedor Docker...
echo [INFO] Argumentos: %*
echo.

REM Ejecutar el contenedor con los argumentos proporcionados
docker run --rm -it -v "%DOWNLOADS_DIR%:/app/downloads" -v "%LOGS_DIR%:/app/logs" -v "%SCRIPT_DIR%:/app/input:ro" %IMAGE_NAME% python descargar_audio.py %*

set EXIT_CODE=%errorlevel%

if %EXIT_CODE%==0 (
    echo.
    echo [SUCCESS] Proceso completado
    echo [INFO] Archivos descargados en: %DOWNLOADS_DIR%
    echo [INFO] Logs guardados en: %LOGS_DIR%
    echo.
) else (
    echo.
    echo [ERROR] El proceso termino con codigo de error: %EXIT_CODE%
)

exit /b %EXIT_CODE%
