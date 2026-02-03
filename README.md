# YouTube to MP3 Converter (CLI)

Herramienta en Python para descargar audio de YouTube y convertirlo a MP3 desde un archivo CSV.

## Inicio rápido (recomendado)
1. Abre PowerShell como administrador.
2. Ejecuta:
   ```powershell
   .\configurar.ps1
   ```
3. Luego:
   ```powershell
   .\ejecutar.ps1 urls.csv
   ```

## Uso
```powershell
.\ejecutar.ps1 urls.csv
.\ejecutar.ps1 urls.csv -o "C:\Mi\Musica"
.\ejecutar.ps1 --help
```

## Formato del CSV
Una URL por fila (encabezado opcional):
```csv
URL
https://www.youtube.com/watch?v=VIDEO_ID_1
https://www.youtube.com/watch?v=VIDEO_ID_2
```

## Alternativa sin scripts
```powershell
venv\Scripts\Activate.ps1
python descargar_audio.py urls.csv
python descargar_audio.py -o "C:\Mi\Musica" urls.csv
```

## Docker (opción rápida)
```bash
docker build -t y2m-cli .
docker run --rm -v "$(pwd)/downloads:/app/downloads" -v "$(pwd):/app/input:ro" y2m-cli /app/input/urls.csv -o /app/downloads
```

## Solución rápida de problemas
- Python no instalado: ejecuta `.\configurar.ps1`.
- FFmpeg no encontrado: ejecuta `.\instalar_ffmpeg.ps1`.
- Execution Policy:
  `Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser`

## Licencia
Código abierto. Úsalo responsablemente y respeta los términos de YouTube.
