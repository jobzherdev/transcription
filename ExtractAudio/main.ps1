# main.ps1 — извлечение аудио из видео в STT-mp3 (mono / 16 kHz / 48 kbps).
# Запускается скрыто через silent-wrapper.vbs. Получает путь к видео как $args[0].
# ВАЖНО: файл сохранён в UTF-8 with BOM (см. ПРОМПТ §12). Не пересохранять без BOM.

[CmdletBinding()]
param([Parameter(Position = 0)][string]$InputPath)

$ErrorActionPreference = 'Stop'
$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path

# ---------------------------------------------------------------------------
# Логирование (UTF-8, ротация при >10 MB)
# ---------------------------------------------------------------------------
function Write-Log {
    param([string]$InFile, [string]$OutFile, [double]$DurationSec, [string]$Status)
    try {
        $logDir = Join-Path $ScriptDir 'логи'
        if (-not (Test-Path -LiteralPath $logDir)) {
            New-Item -ItemType Directory -Path $logDir -Force | Out-Null
        }
        $logFile = Join-Path $logDir 'extract-audio.log'
        if ((Test-Path -LiteralPath $logFile) -and ((Get-Item -LiteralPath $logFile).Length -gt 10MB)) {
            Move-Item -LiteralPath $logFile -Destination "$logFile.old" -Force
        }
        $ts   = Get-Date -Format 'yyyy-MM-dd HH:mm:ss'
        $dur  = if ($DurationSec -gt 0) { [math]::Round($DurationSec, 1) } else { '?' }
        $line = "[$ts] $InFile -> $OutFile | ${dur}s | $Status"
        Add-Content -LiteralPath $logFile -Value $line -Encoding UTF8
    } catch { }
}

# ---------------------------------------------------------------------------
# Валидация входа и поиск ffmpeg
# ---------------------------------------------------------------------------
if ([string]::IsNullOrWhiteSpace($InputPath) -or -not (Test-Path -LiteralPath $InputPath)) {
    Write-Log $InputPath '' 0 'ERROR: input file not found'
    exit 1
}
$ffmpeg  = Join-Path $ScriptDir 'bin\ffmpeg.exe'
$ffprobe = Join-Path $ScriptDir 'bin\ffprobe.exe'
if (-not (Test-Path -LiteralPath $ffmpeg)) {
    Write-Log $InputPath '' 0 'ERROR: bundled ffmpeg.exe not found in bin\'
    exit 1
}

# ---------------------------------------------------------------------------
# Финальное имя (коллизии проверяем ДО префикса INCOMPLETE_, см. §5)
# ---------------------------------------------------------------------------
$dir  = Split-Path -Parent $InputPath
$base = [System.IO.Path]::GetFileNameWithoutExtension($InputPath)
$final = Join-Path $dir ($base + '.mp3')
$n = 2
while (Test-Path -LiteralPath $final) {
    $final = Join-Path $dir ($base + " ($n).mp3")
    $n++
}
$finalName  = Split-Path -Leaf $final
$incomplete = Join-Path $dir ('INCOMPLETE_' + $finalName)

# ---------------------------------------------------------------------------
# Длительность видео (для прогресса). ffprobe → fallback ffmpeg -i.
# ---------------------------------------------------------------------------
function Q([string]$s) {
    if ($s -match '[\s"]') { '"' + ($s -replace '"', '\"') + '"' } else { $s }
}
function Invoke-Native {
    param([string]$Exe, [string]$ArgString)
    $psi = New-Object System.Diagnostics.ProcessStartInfo
    $psi.FileName = $Exe
    $psi.Arguments = $ArgString
    $psi.UseShellExecute = $false
    $psi.CreateNoWindow = $true
    $psi.RedirectStandardOutput = $true
    $psi.RedirectStandardError = $true
    $p = New-Object System.Diagnostics.Process
    $p.StartInfo = $psi
    [void]$p.Start()
    $o = $p.StandardOutput.ReadToEndAsync()
    $e = $p.StandardError.ReadToEndAsync()
    $p.WaitForExit()
    [pscustomobject]@{ ExitCode = $p.ExitCode; StdOut = [string]$o.Result; StdErr = [string]$e.Result }
}

$durationSec = 0.0
try {
    if (Test-Path -LiteralPath $ffprobe) {
        $a = @('-v', 'quiet', '-show_entries', 'format=duration',
               '-of', 'default=nw=1:nk=1', (Q $InputPath)) -join ' '
        $r = Invoke-Native $ffprobe $a
        $val = $r.StdOut.Trim()
        $tmp = 0.0
        if ([double]::TryParse($val, [System.Globalization.NumberStyles]::Float,
                [System.Globalization.CultureInfo]::InvariantCulture, [ref]$tmp)) {
            $durationSec = $tmp
        }
    }
    if ($durationSec -le 0) {
        $a = @('-hide_banner', '-i', (Q $InputPath)) -join ' '
        $r = Invoke-Native $ffmpeg $a   # без output → ffmpeg печатает Duration в stderr
        if ($r.StdErr -match 'Duration:\s*(\d+):(\d+):(\d+(?:\.\d+)?)') {
            $durationSec = [int]$matches[1] * 3600 + [int]$matches[2] * 60 + [double]$matches[3]
        }
    }
} catch { $durationSec = 0.0 }

# ---------------------------------------------------------------------------
# WPF popup
# ---------------------------------------------------------------------------
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        WindowStyle="None" AllowsTransparency="True" Background="Transparent"
        Topmost="True" ShowInTaskbar="False" ShowActivated="False"
        WindowStartupLocation="CenterScreen" SizeToContent="Height" Width="460">
    <Border CornerRadius="12" Background="#E6202020" Padding="20"
            BorderBrush="#40FFFFFF" BorderThickness="1">
        <StackPanel>
            <TextBlock Text="Извлечение аудио" Foreground="White"
                       FontSize="14" FontWeight="SemiBold"/>
            <TextBlock x:Name="txtFile" Foreground="#CCCCCC" FontSize="11"
                       TextTrimming="CharacterEllipsis" Margin="0,4,0,12"/>
            <ProgressBar x:Name="pbar" Height="14" Minimum="0" Maximum="100"
                         Value="0" IsIndeterminate="True"
                         Foreground="#4FC3F7" Background="#33000000"
                         BorderThickness="0"/>
            <TextBlock x:Name="txtPct" Foreground="#AAAAAA" FontSize="10"
                       HorizontalAlignment="Right" Margin="0,6,0,0"/>
        </StackPanel>
    </Border>
</Window>
"@

$reader = New-Object System.Xml.XmlNodeReader $xaml
$window = [Windows.Markup.XamlReader]::Load($reader)

$script:pbar    = $window.FindName('pbar')
$script:txtPct  = $window.FindName('txtPct')
$txtFile        = $window.FindName('txtFile')
$txtFile.Text   = Split-Path -Leaf $InputPath

if ($durationSec -gt 0) { $script:pbar.IsIndeterminate = $false }

# ---------------------------------------------------------------------------
# Запуск ffmpeg (System.Diagnostics.Process, async stderr, -progress в temp)
# ---------------------------------------------------------------------------
$progressFile = [System.IO.Path]::GetTempFileName()

$argString = @(
    '-hide_banner', '-loglevel', 'error', '-nostats', '-y',
    '-progress', (Q $progressFile),
    '-i', (Q $InputPath),
    '-vn', '-ac', '1', '-ar', '16000', '-b:a', '48k',
    (Q $incomplete)
) -join ' '

$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = $ffmpeg
$psi.Arguments = $argString
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
$psi.RedirectStandardError = $true

$script:proc = New-Object System.Diagnostics.Process
$script:proc.StartInfo = $psi
try {
    [void]$script:proc.Start()
} catch {
    Write-Log $InputPath $finalName $durationSec ("ERROR: cannot start ffmpeg: " + $_.Exception.Message)
    Remove-Item -LiteralPath $progressFile -Force -ErrorAction SilentlyContinue
    exit 1
}
$script:stderrTask     = $script:proc.StandardError.ReadToEndAsync()
$script:userInterrupted = $false
$script:durationSec     = $durationSec
$script:progressFile    = $progressFile

# ---------------------------------------------------------------------------
# Таймер прогресса (UI-поток — DispatcherTimer безопасен, см. §12)
# ---------------------------------------------------------------------------
$script:timer = New-Object System.Windows.Threading.DispatcherTimer
$script:timer.Interval = [TimeSpan]::FromMilliseconds(200)
$script:timer.add_Tick({
    try {
        if ($script:durationSec -gt 0 -and (Test-Path -LiteralPath $script:progressFile)) {
            $fs = [System.IO.File]::Open($script:progressFile, 'Open', 'Read', 'ReadWrite')
            $sr = New-Object System.IO.StreamReader($fs)
            $text = $sr.ReadToEnd(); $sr.Close(); $fs.Close()
            $m = [regex]::Matches($text, 'out_time=(\d+):(\d+):(\d+(?:\.\d+)?)')
            if ($m.Count -gt 0) {
                $last = $m[$m.Count - 1]
                $sec = [int]$last.Groups[1].Value * 3600 + [int]$last.Groups[2].Value * 60 + [double]$last.Groups[3].Value
                $pct = [math]::Min(100, [math]::Max(0, ($sec / $script:durationSec) * 100))
                $script:pbar.Value = $pct
                $script:txtPct.Text = ('{0:N0} %' -f $pct)
            }
        }
    } catch { }
    if ($script:proc.HasExited) {
        $script:timer.Stop()
        $script:window.Close()
    }
})

$script:window = $window
$window.add_Closing({
    if (-not $script:proc.HasExited) {
        $script:userInterrupted = $true
        try { $script:proc.Kill() } catch { }
    }
})
$window.add_Closed({ [System.Windows.Threading.Dispatcher]::ExitAllFrames() })

$script:timer.Start()
$window.Show()                                   # Show() (не ShowDialog) — не крадёт фокус
[System.Windows.Threading.Dispatcher]::Run()

# ---------------------------------------------------------------------------
# Пост-обработка: rename / delete / keep + лог (см. §5)
# ---------------------------------------------------------------------------
if (-not $script:proc.HasExited) {
    $script:userInterrupted = $true
    try { $script:proc.Kill() } catch { }
}
$script:proc.WaitForExit()
$exitCode = $script:proc.ExitCode
$stderr   = [string]$script:stderrTask.Result
Remove-Item -LiteralPath $progressFile -Force -ErrorAction SilentlyContinue

$isKilled = $script:userInterrupted -or ([string]::IsNullOrWhiteSpace($stderr) -and $exitCode -ne 0)

if ($exitCode -eq 0 -and -not $script:userInterrupted) {
    try {
        Move-Item -LiteralPath $incomplete -Destination $final -Force
        Write-Log $InputPath $finalName $durationSec 'OK'
    } catch {
        Write-Log $InputPath $finalName $durationSec ("ERROR: rename failed: " + $_.Exception.Message)
    }
}
elseif ($isKilled) {
    # Прервано пользователем / выключением — INCOMPLETE_ остаётся как видимый маркер.
    Write-Log $InputPath ('INCOMPLETE_' + $finalName) $durationSec 'INTERRUPTED (kept INCOMPLETE_)'
}
else {
    # Реальная ошибка ffmpeg — удаляем частичный файл, причина в лог.
    Remove-Item -LiteralPath $incomplete -Force -ErrorAction SilentlyContinue
    $reason = ($stderr -split "`n" | Where-Object { $_.Trim() } | Select-Object -First 1)
    Write-Log $InputPath $finalName $durationSec ("ERROR (exit $exitCode): " + $reason)
}
