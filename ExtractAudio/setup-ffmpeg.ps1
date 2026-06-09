# setup-ffmpeg.ps1 — скачивает bundled ffmpeg.exe + ffprobe.exe в bin\.
# Запускается автоматически из install.ps1, либо вручную.

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot
$bin = Join-Path $ScriptDir 'bin'
if (-not (Test-Path -LiteralPath $bin)) {
    New-Item -ItemType Directory -Path $bin -Force | Out-Null
}
$ff = Join-Path $bin 'ffmpeg.exe'
if (Test-Path -LiteralPath $ff) {
    Write-Host 'ffmpeg.exe уже на месте.' -ForegroundColor Green
    return
}

$url = 'https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.zip'
$zip = Join-Path $env:TEMP ('ffmpeg_' + [guid]::NewGuid().ToString('N') + '.zip')
$tmp = Join-Path $env:TEMP ('ffmpeg_' + [guid]::NewGuid().ToString('N'))

Write-Host "Скачиваю ffmpeg (~96 MB) с $url ..." -ForegroundColor Yellow
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
Invoke-WebRequest -Uri $url -OutFile $zip -UseBasicParsing

Write-Host 'Распаковываю...' -ForegroundColor Yellow
Expand-Archive -LiteralPath $zip -DestinationPath $tmp -Force

$srcFf    = Get-ChildItem -LiteralPath $tmp -Recurse -Filter 'ffmpeg.exe'  | Select-Object -First 1
$srcProbe = Get-ChildItem -LiteralPath $tmp -Recurse -Filter 'ffprobe.exe' | Select-Object -First 1
if (-not $srcFf) { throw 'ffmpeg.exe не найден в скачанном архиве.' }
Copy-Item -LiteralPath $srcFf.FullName -Destination $ff -Force
if ($srcProbe) {
    Copy-Item -LiteralPath $srcProbe.FullName -Destination (Join-Path $bin 'ffprobe.exe') -Force
}

Remove-Item -LiteralPath $zip -Force -ErrorAction SilentlyContinue
Remove-Item -LiteralPath $tmp -Recurse -Force -ErrorAction SilentlyContinue
Write-Host 'ffmpeg установлен в bin\.' -ForegroundColor Green
