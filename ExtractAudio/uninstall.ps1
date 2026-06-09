# uninstall.ps1 — удаляет ключи контекстного меню из HKCU.
# Файлы утилиты остаются на диске. Запускается из uninstall.cmd.

$ErrorActionPreference = 'Stop'
$exts = @('.mp4', '.mkv', '.mov', '.webm', '.avi', '.m4v',
          '.flv', '.ts', '.wmv', '.mpg', '.mpeg')
$verb = 'ExtractAudio'

foreach ($ext in $exts) {
    $key = "HKCU:\Software\Classes\SystemFileAssociations\$ext\shell\$verb"
    if (Test-Path -LiteralPath $key) {
        Remove-Item -Path $key -Recurse -Force
    }
}

Write-Host 'Готово! Пункт «Извлечь аудио» удалён из контекстного меню.' -ForegroundColor Green
Write-Host 'Файлы утилиты остались на диске — удалите папку вручную, если нужно.' -ForegroundColor Cyan
