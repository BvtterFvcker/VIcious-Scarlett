# GAoR Launcher copy of play-3070.ps1: long pipeline wait on the first run (via VICTORY_PIPELINE_WAIT_MS), THIN off (RTX 50 blur).
param(
    [Parameter(Mandatory)][string]$Game,
    [ValidateSet('series-s', 'series-x')][string]$Console = 'series-s',
    [ValidateRange(0, 3)][int]$MipDrop = 1,
    [int]$CardBuffersMB = 1024,
    [int]$CardWindowsMB = 512,
    [switch]$Hooks,
    [switch]$ProbeRays,
    [switch]$RayTracing,
    [switch]$Prewarm,
    [switch]$Diag,  # diagnostics build (target\diag) + per-copy refresh reports
    [string[]]$Extra = @()   # extra NAME=VALUE switches for one A/B run
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$exe = Join-Path $root $(if ($Diag) { 'target\diag\victory.exe' } else { 'target\release\victory.exe' })
if (-not (Test-Path -LiteralPath $exe)) {
    $exe = Join-Path $root 'victory.exe'
}
if (-not (Test-Path -LiteralPath $exe)) {
    throw "Release binary not found next to script or in target\release\victory.exe"
}
if (-not (Test-Path -LiteralPath $Game)) {
    throw "Game not found: $Game"
}
if (Get-Process victory -ErrorAction SilentlyContinue) {
    Write-Host "victory.exe is already running." -ForegroundColor Yellow
    exit 1
}

# Clear inherited VICTORY_* except path overrides (keeps default save & cache)
$keep = 'VICTORY_CONFIG', 'VICTORY_GAME_DIR', 'VICTORY_CACHE_DIR', 'VICTORY_DATA_DIR', 'VICTORY_PIPELINE_WAIT_MS'
Get-ChildItem Env:VICTORY_* -ErrorAction SilentlyContinue | Where-Object { $_.Name -notin $keep } | ForEach-Object { Remove-Item "Env:$($_.Name)" }

$gameDir = Split-Path -Parent (Resolve-Path -LiteralPath $Game)
$set = [ordered]@{
    VICTORY_GAME_DIR             = $gameDir
    VICTORY_PIPELINE_BOOK        = '1'
    VICTORY_LOG                  = 'info'
    VICTORY_FRAME_INTERVAL_MS    = '16.667'

    # RTX 3070 8GB VRAM budget + Scarlett page pool (-1.2 GB texture VRAM)
    VICTORY_DYNAMIC_SLOTS        = '524288'
    VICTORY_MAX_PRELUDES         = '32'
    VICTORY_CARD_BUFFERS_MB      = "$CardBuffersMB"
    VICTORY_CARD_WINDOWS_MB      = "$CardWindowsMB"
    VICTORY_TEXTURE_MIP_DROP     = "$MipDrop"
    VICTORY_TEXTURE_ROOM_PERCENT = '94'
    VICTORY_PAGE_POOL            = '1'
    VICTORY_STAGING_PACK         = '1'
    VICTORY_LEVELS_ON_DEMAND     = '0'

    # Scarlett CPU submit & upload wins (+ 3050 Nsight A/B tweaks)
    VICTORY_WAIT_RESIDENT        = '0'
    VICTORY_JOIN_COPIES          = '0'
    VICTORY_REFRESH_ONCE         = '1'
    VICTORY_CARD_REHASH_RUNS     = '1'
    VICTORY_BACK_OWN_VIEW        = '1'
    VICTORY_WIDE_MERGE           = '1'
    VICTORY_MIRROR_FAST          = '1'
    VICTORY_PIPELINE_WAIT_MS     = $(if ($env:VICTORY_PIPELINE_WAIT_MS) { $env:VICTORY_PIPELINE_WAIT_MS } else { '20' })   # launcher: 10000 on the first run (world not black while pipelines compile)
    VICTORY_THIN                 = '0'         # launcher: THIN blurs the image on RTX 50 (Blackwell) cards
    VICTORY_ASYNC_SUBMIT         = '1'
    VICTORY_QUEUE2               = '1'
    VICTORY_INDIRECT_WINDOW      = '1'
    VICTORY_TEXTURE_NO_WAIT      = '1'
    VICTORY_COPY_PLAIN           = '1'
    VICTORY_WIDE_TEXTURES        = '1'
    VICTORY_INDIRECT_GATHER      = '1'
    VICTORY_LATE_WAIT_LISTS      = '1024'
    VICTORY_CARD_FILLS_BATCH     = '0'
    VICTORY_GATHER_DISPATCH      = '0'
    VICTORY_RELAY                = '2'
    VICTORY_WIDE_BACK            = '1'
    VICTORY_RELAY_COPY           = '1'
    VICTORY_CARD_STEPS           = '2'
    VICTORY_INDIRECT_BATCH       = '2'
    VICTORY_MAP_THREADS          = '1'
    VICTORY_CARD_AWAKE           = '0'
    VICTORY_SHOW_AFTER           = '1'
    VICTORY_JOIN_PARTS           = '8'
    VICTORY_UPLOAD_AHEAD         = '1'
    VICTORY_CARD_BUFFERS_MIN_KB  = '64'
    VICTORY_POOL_DISCARD         = '1'
    VICTORY_FILL_TITLE           = '1'
    VICTORY_PARTIAL_DELTA        = '1'
    VICTORY_BAKE_DELTA           = '1'
    VICTORY_MAP_LOCK_FINE        = '1'
    VICTORY_POOL_CAP             = '1'
    VICTORY_TABLE_MEMO           = '1'
    VICTORY_LIST_ALIAS_EXACT     = '1'
    VICTORY_LIST_HOLD            = '1'
    VICTORY_EARLY_TEXTURES_MS    = '40'
    VICTORY_BAKE_TEXTURES_MS     = '10000'
    VICTORY_HEAP_PASS_MAX        = '0'
    VICTORY_HEAP_CHANGED_MAX     = '0'
    # (VIcious 11-27) + trustno1's two water-light shaders (dark sea tiles on 32-lane cards, ~15 ms of the card).
    # Since the VIcious build this list works in release builds too (it did nothing there before).
    VICTORY_SKIP_PIPELINES       = '02384a60fda6f2d0,731a39171b568298,5dc3b25986622949,6f225b641c5b0708'
    # (VIcious 11-27, E run 2) one merged guard pass per submission, refreshes still check (no stale data),
    # and unchanged ranges answered by their stamp: 15-20 % less time a frame in heavy scenes, picture as before.
    VICTORY_ASK_ONCE_GUARDS      = 'verify'
    VICTORY_CLEAN_STAMP          = '1'
    VICTORY_WC_NO_BACK           = '1'
    VICTORY_WC_NO_BACK_MIN_KB    = '1024'
    VICTORY_SYNC_IN_PLACE        = '1'
    VICTORY_SPANS_QUICK          = '1'
    VICTORY_SYNC_FINE            = '1'
    VICTORY_HEAP_SYNC_FIRST      = '1'
    VICTORY_SOFT_VIEWS           = 'copies'
    # (VIcious 11-27) 0: static-sampler pipelines load from the library (no ~1,950 recompiles each launch,
    # the driving stutter); no banding seen on the RTX 5060. Was 1.
    VICTORY_SAMPLERS_MADE        = '0'
    # (VIcious 11-27) the card reads title memory in place (no copy, refresh or copy-back for it), the page
    # pool committed so it can be opened (needs the 40-48 GB page file). E run 11-27 10:35: 15-25 % less
    # time a frame at equal draws (6k draws 99 -> 75 ms, 8k 112 -> 85 ms), 18 fps peaks in the house.
    # (VIcious 11-27) NVIDIA's DLSS files, this build's own copy (used when VICTORY_DLSS=1).
    VICTORY_STREAMLINE_DIR       = (Join-Path $root 'nvidia-sdk\Streamline\bin\x64')
    VICTORY_INPLACE              = '2'
    VICTORY_INPLACE_MB           = '1536'
    VICTORY_POOL_COMMIT          = '1'
    VICTORY_TABLE_NAMED_ONLY     = '1'
    VICTORY_QUEUE_MARKS          = '1'
}
if ($Hooks) {
    $set.VICTORY_GPU_ONLY = '1'
    $set.VICTORY_KNOWN_WRITES = '1'
}
if ($ProbeRays -and -not $RayTracing) {
    $set.VICTORY_PROBE_RAYS = '1'
    $set.VICTORY_PLANE_NOW = '1'
} elseif (-not $RayTracing) {
    $set.VICTORY_AMBIENT = '0.8'
    $set.VICTORY_AMBIENT_AIR = '1.5'
}
if ($RayTracing) { $set.VICTORY_BVH_BUILDER = '1' }
if ($Diag) {
    $set.VICTORY_REFRESH_ACCOUNT = '1'
    $set.VICTORY_REFRESH_SPLIT = '1'
}
foreach ($kv in ($Extra -split ';' | Where-Object { $_ -match '=' })) { $k, $v = $kv -split '=', 2; $set[$k.Trim()] = $v.Trim() }

foreach ($k in $set.Keys) { Set-Item -Path "Env:$k" -Value $set[$k] }

if ($Prewarm) {
    Write-Host "Prewarming shaders and pipelines..." -ForegroundColor Cyan
    & $exe shaders $gameDir
    & $exe warm
}

$runsDir = Join-Path $root 'runs'
New-Item -ItemType Directory -Force -Path $runsDir | Out-Null
$stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
$logPath = Join-Path $runsDir "3070-$stamp.log"

Write-Host "=== VIcious Scarlett (release, $Console, MipDrop=$MipDrop, PagePool=1) ===" -ForegroundColor Green
Write-Host "Log: $logPath"
$ErrorActionPreference = 'Continue'
& $exe run $Game --execute --console $Console 2>&1 | Tee-Object -FilePath $logPath
exit $LASTEXITCODE
