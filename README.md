# YouTube to MP3 Converter - CLI

Un script en Python que descarga audio de videos de YouTube y los convierte a formato MP3.

<!--**Nota**: Este es el repositorio de la **aplicaciÃ³n de lÃ­nea de comandos (CLI)**. Si buscas la interfaz web, visita [y2m-web](../y2m-web).-->

## ðŸŒŸ CaracterÃ­sticas

- âœ… **Descarga audio de alta calidad** (320 kbps)
- âœ… **Convierte automÃ¡ticamente a MP3**
- âœ… **Procesamiento en lote desde archivo CSV**
- âœ… **Soporte Docker** - Ejecuta sin instalar dependencias
- âœ… Limpia nombres de archivo problemÃ¡ticos
- âœ… Muestra progreso de descarga en tiempo real
- âœ… Interfaz de lÃ­nea de comandos mejorada
- âœ… Manejo de errores robusto
- âœ… Resumen detallado de procesamiento

## Requisitos

- Python 3.7+
- FFmpeg (debe estar instalado en el sistema y disponible en PATH)
- yt-dlp (incluido en requirements.txt)

## InstalaciÃ³n

### ðŸš€ ConfiguraciÃ³n AutomÃ¡tica (Recomendado)

El proyecto incluye un script de configuraciÃ³n automÃ¡tico que se encarga de todo:

1. **Descarga el proyecto** a tu ordenador
2. **Abre PowerShell como administrador** (clic derecho â†’ "Ejecutar como administrador")
3. **Navega al directorio del proyecto**:
   ```powershell
   cd "C:\ruta\a\tu\proyecto\y2m-cli"
   ```
4. **Ejecuta la configuraciÃ³n automÃ¡tica**:
   ```powershell
   # OpciÃ³n 1: PowerShell (mÃ¡s completo, instala Python/FFmpeg automÃ¡ticamente)
   .\configurar.ps1
   
   # OpciÃ³n 2: Batch (mÃ¡s compatible, requiere Python pre-instalado)
   configurar.bat
   ```

Este script automÃ¡ticamente:
- âœ… Verifica e instala Python 3.11.9 si es necesario
- âœ… Verifica e instala FFmpeg si es necesario  
- âœ… Crea el entorno virtual
- âœ… Instala todas las dependencias
- âœ… Verifica que todo funciona correctamente

### ðŸ”§ ConfiguraciÃ³n Manual (Alternativa)

Si prefieres configurar manualmente:

1. Instala Python 3.7+ desde [python.org](https://www.python.org/downloads/)
2. Instala FFmpeg desde [ffmpeg.org](https://ffmpeg.org/download.html)
3. Clona o descarga este repositorio
4. Activa el entorno virtual:
   ```bash
   venv\Scripts\Activate.ps1  # Windows PowerShell
   # o
   venv\Scripts\activate.bat  # Windows CMD
   ```
5. Instala las dependencias:
   ```bash
   pip install -r requirements.txt
   ```

## ðŸ³ Docker (OpciÃ³n mÃ¡s fÃ¡cil)

Â¿Quieres la forma mÃ¡s rÃ¡pida de empezar? Usa Docker:

```bash
# Construir imagen
docker build -t y2m-cli .

# Procesar un CSV (URLs por fila)
docker run --rm ^
  -v "$(pwd)/downloads:/app/downloads" ^
  -v "$(pwd):/app/input:ro" ^
  y2m-cli /app/input/urls.csv -o /app/downloads

# Ver ayuda
docker run --rm y2m-cli --help
```

**Ventajas de Docker:**
- âœ… No necesitas instalar Python, FFmpeg ni dependencias
- âœ… Funciona en Windows, Mac y Linux
- âœ… ConfiguraciÃ³n en un solo comando

**Script Docker incluido (recomendado):**
```powershell
.\ejecutar.ps1 urls.csv
```

## Uso

### ðŸŽ¯ Uso Simplificado (Recomendado)

DespuÃ©s de la configuraciÃ³n automÃ¡tica, usa el script ejecutor:

**Procesamiento desde CSV (obligatorio):**
```powershell
.\ejecutar.ps1 urls.csv
```

**CSV con directorio de salida personalizado:**
```powershell
.\ejecutar.ps1 urls.csv -o "C:\Mi\Carpeta\Musica"
```

**Ver ayuda detallada:**
```powershell
.\ejecutar.ps1 --help
```

### ðŸ”§ Uso Manual (Si no usas el ejecutor)

**Activar entorno virtual primero:**
```powershell
venv\Scripts\Activate.ps1
```

**Luego usar el script Python directamente:**
```bash
python descargar_audio.py urls.csv
python descargar_audio.py -o "C:\Mi\Musica" urls.csv
```

### Opciones disponibles
- `csv_file`: Archivo CSV con URLs (una por fila)
- `-h, --help`: Muestra ayuda
- `-o, --output-dir`: Especifica directorio de salida
- `--version`: Muestra versiÃ³n del programa

## Formato del archivo CSV

El archivo CSV debe contener las URLs de YouTube, una por fila. Puede incluir un encabezado opcional:

```csv
URL
https://www.youtube.com/watch?v=VIDEO_ID_1
https://www.youtube.com/watch?v=VIDEO_ID_2
https://www.youtube.com/watch?v=VIDEO_ID_3
```

O sin encabezado:

```csv
https://www.youtube.com/watch?v=VIDEO_ID_1
https://www.youtube.com/watch?v=VIDEO_ID_2
https://www.youtube.com/watch?v=VIDEO_ID_3
```

### CaracterÃ­sticas del procesamiento CSV:
- âœ… Detecta automÃ¡ticamente si hay encabezados
- âœ… Ignora lÃ­neas vacÃ­as
- âœ… Valida cada URL antes de procesar
- âœ… Muestra progreso detallado para cada descarga
- âœ… Resumen final con estadÃ­sticas
- âœ… Manejo de interrupciones (Ctrl+C) con resumen parcial

## Scripts Incluidos

### ðŸ› ï¸ Configuradores

**configurar.ps1** - ConfiguraciÃ³n avanzada (PowerShell)
```powershell
.\configurar.ps1              # ConfiguraciÃ³n completa con instalaciÃ³n automÃ¡tica
.\configurar.ps1 -SkipFFmpeg  # Omitir instalaciÃ³n de FFmpeg
```

**configurar.bat** - ConfiguraciÃ³n simple (Batch)
```batch
configurar.bat                # ConfiguraciÃ³n bÃ¡sica (requiere Python pre-instalado)
```

### ðŸš€ Ejecutores

**ejecutar.ps1** - Ejecutor principal (Docker)
```powershell
.\ejecutar.ps1 urls.csv       # Ejecuta el programa (CSV obligatorio)
.\ejecutar.ps1 --help         # Muestra ayuda rÃ¡pida
```

### ðŸŽ¥ Herramientas adicionales

**instalar_ffmpeg.ps1** - Instalador de FFmpeg
```powershell
.\instalar_ffmpeg.ps1        # Instala sÃ³lo FFmpeg
```

**docker-cli.ps1** - Wrapper (deprecado)
```powershell
.\docker-cli.ps1 urls.csv     # Redirige a ejecutar.ps1
```

## SoluciÃ³n de problemas

### ðŸš‘ ConfiguraciÃ³n

**Error: "Python no estÃ¡ instalado"**
- Ejecuta `.\configurar.ps1` como administrador
- O instala Python manualmente desde [python.org](https://www.python.org/downloads/)

**Error: "FFmpeg not found"**
- Ejecuta `.\instalar_ffmpeg.ps1`
- O ejecuta `.\configurar.ps1` de nuevo
- O instala FFmpeg manualmente desde [ffmpeg.org](https://ffmpeg.org/download.html)

**Error: "No se encontrÃ³ el entorno virtual"**
- Ejecuta `.\configurar.ps1` para crear el entorno
- AsegÃºrate de estar en el directorio correcto del proyecto

### ðŸ“± EjecuciÃ³n

**Error de descarga**
- Verifica que la URL del video sea correcta
- AsegÃºrate de tener conexiÃ³n a internet
- Algunos videos pueden estar restringidos por regiÃ³n o privados
- Prueba con una URL diferente

**Caracteres especiales en nombres de archivo**
- El script limpia automÃ¡ticamente los caracteres problemÃ¡ticos
- Los archivos se guardan con nombres seguros para el sistema de archivos

**Error: "Execution Policy"**
- Ejecuta: `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`
- O ejecuta: `PowerShell -ExecutionPolicy Bypass -File .\configurar.ps1`

### ðŸ“ CSV

**El archivo CSV no se procesa correctamente**
- Verifica que el archivo tenga URLs vÃ¡lidas (que empiecen con http:// o https://)
- AsegÃºrate de que no haya lÃ­neas vacÃ­as extra
- El formato debe ser una URL por lÃ­nea

## Relacionado

- **Interfaz Web**: [y2m-web](../y2m-web) - VersiÃ³n con interfaz grÃ¡fica y API REST

## Licencia

Este proyecto es de cÃ³digo abierto. Ãšsalo responsablemente y respeta los tÃ©rminos de servicio de YouTube.


