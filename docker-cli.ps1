# Deprecated wrapper. Use ejecutar.ps1 instead.
Write-Host "[INFO] docker-cli.ps1 is deprecated. Use ejecutar.ps1." -ForegroundColor Yellow
& "$PSScriptRoot\ejecutar.ps1" @args
exit $LASTEXITCODE
