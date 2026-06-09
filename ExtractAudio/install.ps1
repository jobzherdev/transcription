# install.ps1 — регистрирует пункт «Извлечь аудио» в контекстном меню Проводника.
# HKCU (без admin / без UAC). Запускается из install.cmd.
# UTF-8 with BOM (содержит кириллицу).

$ErrorActionPreference = 'Stop'
$ScriptDir = $PSScriptRoot
$vbs = Join-Path $ScriptDir 'silent-wrapper.vbs'

# Скачать ffmpeg, если его ещё нет рядом.
$ffmpeg = Join-Path $ScriptDir 'bin\ffmpeg.exe'
if (-not (Test-Path -LiteralPath $ffmpeg)) {
    Write-Host 'ffmpeg.exe не найден в bin\ — пытаюсь скачать...' -ForegroundColor Yellow
    & (Join-Path $ScriptDir 'setup-ffmpeg.ps1')
}
if (-not (Test-Path -LiteralPath $ffmpeg)) {
    Write-Host 'ОШИБКА: ffmpeg.exe отсутствует. Положите ffmpeg.exe в папку bin\ вручную' -ForegroundColor Red
    Write-Host '(скачать: https://www.gyan.dev/ffmpeg/builds/ — essentials build).' -ForegroundColor Red
    exit 1
}

$exts = @('.mp4', '.mkv', '.mov', '.webm', '.avi', '.m4v',
          '.flv', '.ts', '.wmv', '.mpg', '.mpeg')
$verb     = 'ExtractAudio'
$menuText = 'Извлечь аудио'
$icon     = '%SystemRoot%\System32\mmcndmgr.dll,30'
$command  = 'wscript.exe "' + $vbs + '" "%1"'

foreach ($ext in $exts) {
    $key = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\$verb"
    New-Item -Path $key -Force | Out-Null
    Set-ItemProperty -Path $key -Name '(default)' -Value $menuText
    New-ItemProperty -Path $key -Name 'Icon' -Value $icon -PropertyType ExpandString -Force | Out-Null
    New-Item -Path "$key\command" -Force | Out-Null
    Set-ItemProperty -Path "$key\command" -Name '(default)' -Value $command
}

Write-Host ''
Write-Host 'Готово! Пункт «Извлечь аудио» добавлен в контекстное меню для:' -ForegroundColor Green
Write-Host ('  ' + ($exts -join '  '))
Write-Host ''
Write-Host 'Правый клик по видеофайлу -> «Извлечь аудио».' -ForegroundColor Cyan
Write-Host 'ВАЖНО: не перемещайте эту папку после установки (пути в реестре абсолютные).' -ForegroundColor Yellow
