# YouTube to MP3 Downloader - CLI Docker Container
FROM python:3.11-alpine

# Install runtime dependencies
RUN apk add --no-cache \
    ffmpeg \
    && rm -rf /var/cache/apk/*

# Set working directory
WORKDIR /app

# Copy requirements and install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy CLI script
COPY descargar_audio.py .

# Create directories for downloads and logs
RUN mkdir -p /app/downloads /app/logs

# Configure environment variables
ENV PYTHONUNBUFFERED=1
ENV PYTHONIOENCODING=utf-8
ENV DOWNLOAD_DIR=/app/downloads
ENV LOGS_DIR=/app/logs

# Non-root user for security
RUN adduser -D -g '' appuser && \
    chown -R appuser:appuser /app
USER appuser

# Entry point for CLI application
ENTRYPOINT ["python", "descargar_audio.py"]

# Default: show help
CMD ["--help"]
