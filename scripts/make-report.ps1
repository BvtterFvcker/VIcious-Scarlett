# VIcious Scarlett performance report: reads the newest runs\3070-*.log and writes runs\report-<date>.txt
# (also copied to the clipboard) to send to the author. Only warm frames count (no pipelines being made),
# grouped by draws per frame so different PCs compare fairly in similar scenes.
param([string]$Log = '')
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$runs = Join-Path $root 'runs'
if (-not $Log) {
    $f = Get-ChildItem $runs -Filter '3070-*.log' -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $f) { throw "No log in $runs. Play once first (menu A or B), then make the report." }
    $Log = $f.FullName
}
$text = [IO.File]::ReadAllText($Log)                       # UTF-16 or UTF-8, detected by BOM
$text = $text -replace "`e\[[0-9;]*m", '' -replace "\r?\n", ''   # the console wraps long lines at a fixed width: join without a space

# One summary per frame window: "<fps> fps, <ms> ms/frame (... <n> draws/frame, ... (<k> being made) ...".
# "being made" is only printed while pipelines are compiling; absent = 0.
$heads = [regex]::Matches($text, '(\d+(?:\.\d+)?) fps, (\d+(?:\.\d+)?) ms/frame \(')
$frames = for ($i = 0; $i -lt $heads.Count; $i++) {
    $h = $heads[$i]
    $end = if ($i + 1 -lt $heads.Count) { $heads[$i + 1].Index } else { $text.Length }
    $seg = $text.Substring($h.Index, [math]::Min($end - $h.Index, 6000))
    $d = [regex]::Match($seg, '(\d+) draws/frame,')
    if (-not $d.Success) { continue }
    $k = [regex]::Match($seg, '\((\d+) being made\)')
    [pscustomobject]@{ Ms = [double]$h.Groups[2].Value; Draws = [int]$d.Groups[1].Value; Making = $(if ($k.Success) { [int]$k.Groups[1].Value } else { 0 }) }
}
$warm = @($frames | Where-Object { $_.Making -eq 0 -and $_.Draws -ge 500 })
$median = { param($v) $s = @($v | Sort-Object); if ($s.Count) { $s[[int][math]::Floor($s.Count / 2)] } else { 0 } }

$lines = @()
$lines += "VIcious Scarlett performance report  $(Get-Date -Format 'yyyy-MM-dd HH:mm')"
$lines += "Log: $(Split-Path -Leaf $Log)"
$os = Get-CimInstance Win32_OperatingSystem
$cpu = (Get-CimInstance Win32_Processor | Select-Object -First 1).Name.Trim()
$gpus = (Get-CimInstance Win32_VideoController | ForEach-Object { "$($_.Name) (driver $($_.DriverVersion))" }) -join '; '
$lines += "CPU: $cpu"
$lines += "GPU: $gpus"
$lines += "RAM: $([math]::Round($os.TotalVisibleMemorySize / 1MB)) GB, RAM + page file: $([math]::Round($os.TotalVirtualMemorySize / 1MB)) GB"
$lines += "Windows: $($os.Caption) $($os.BuildNumber)"
$dlss = if ($text -match 'VICTORY_DLSS=1|DLSS per frame|upscaling recorded') { 'on' } else { 'off' }
$lines += "DLSS: $dlss"
$lines += ''
$lines += "Warm frames (no pipelines being made): $($warm.Count) of $(@($frames).Count) measured"
$lines += ''
$lines += 'Draws/frame   samples   median ms   median fps'
foreach ($b in @(@(500, 2000), @(2000, 4000), @(4000, 6000), @(6000, 8000), @(8000, 10000), @(10000, 99999))) {
    $in = @($warm | Where-Object { $_.Draws -ge $b[0] -and $_.Draws -lt $b[1] })
    if (-not $in.Count) { continue }
    $ms = & $median ($in | ForEach-Object Ms)
    $label = if ($b[1] -gt 50000) { "$($b[0])+" } else { "$($b[0])-$($b[1])" }
    $lines += '{0,-13} {1,7}   {2,9:N1}   {3,10:N1}' -f $label, $in.Count, $ms, (1000 / $ms)
}
if (-not $warm.Count) { $lines += '(no warm frames yet: play longer, or warm first with menu W)' }
$lines += ''
$lines += "For BvtterFvcker: paste in a new issue at github.com/BvtterFvcker/VIcious-Scarlett/issues"
$lines += 'Where were you (day/night, city/indoors, driving)? Anything that looked wrong?'

New-Item -ItemType Directory -Force -Path $runs | Out-Null
$out = Join-Path $runs "report-$(Get-Date -Format 'yyyyMMdd-HHmmss').txt"
$lines | Set-Content -Path $out -Encoding utf8
$lines | Set-Clipboard
$lines | ForEach-Object { Write-Host $_ }
Write-Host ''
Write-Host "Saved to $out and copied to the clipboard." -ForegroundColor Green
Write-Host "Send it to BvtterFvcker: paste it in a new issue at https://github.com/BvtterFvcker/VIcious-Scarlett/issues/new" -ForegroundColor Green
Start-Process "https://github.com/BvtterFvcker/VIcious-Scarlett/issues/new"
