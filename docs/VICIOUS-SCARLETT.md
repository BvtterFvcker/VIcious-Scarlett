# VIcious Scarlett: how it works, what we changed, where it came from

## How it works (short)

VIcious Scarlett is an Xbox Series ("Scarlett") emulator for Windows that runs **Grand Adventure of Robberies**
from your own dump. Nothing from the game is in this repository.

| Part | Crate | What it does |
|---|---|---|
| Loader | `crates/victory-loader` | Maps the title's executable into memory, binds its imports, sets the frame rate the title asks for. |
| System (HLE) | `crates/victory-hle` | Re-implements the console's OS, graphics, audio and input APIs the title calls, on Windows. |
| Shader translator | `crates/victory-shader` | Turns the console GPU's (RDNA / GFX10) shader code into DXIL for D3D12. |
| GPU | `crates/victory-gpu` | Replays the title's GPU command lists on D3D12: pipelines, textures, memory tracking, presenting, DLSS. |
| Runner | `apps/victory` | The `victory.exe` commands: `run`, `shaders` (translate all shaders once), `warm` (make all recorded pipelines ahead of time). |

The hard part is memory. The console has one memory shared by CPU and GPU, while a PC has RAM and VRAM apart.
The emulator has to notice what the title writes, copy it to the card, and copy GPU results back. Most of my work
is about doing less of that per frame.

Every setting is an environment variable `VICTORY_*`. The launcher script (`scripts/play-3070-launcher.ps1`) sets the
measured defaults in its `$set` table; `-Extra "K=V;K=V"` adds more for one run.

## What I changed (on top of Yaekai/victory-scarlett-3070, branch scarlett-fox)

Tested on an RTX 5060 Laptop 8 GB, Ryzen 9 8940HX, 24 GB RAM, Windows 11. Goal: 20+ real fps (no frame generation).

**Faster per frame** (same-draw-count comparison against our starting point: 3k draws 65 → 57 ms,
6k draws 99 → 75 ms, 8k draws 112 → 85 ms):
- `VICTORY_ASK_ONCE_GUARDS=verify`, `VICTORY_CLEAN_STAMP=1`: one merged guard pass per submission; unchanged ranges
  answered by their stamp (15–20 % less time a frame in heavy scenes, picture unchanged).
- `VICTORY_INPLACE=2`, `VICTORY_INPLACE_MB=1536`, `VICTORY_POOL_COMMIT=1`: the card reads title memory in place
  (no copy / refresh / copy-back). Code: page pool committed (`SEC_COMMIT`) and placed in that section so D3D12 can
  open it as a heap. Needs RAM + page file of about 48 GB.
- `VICTORY_SAMPLERS_MADE=0`: ~1,950 static-sampler pipelines load from the pipeline library instead of compiling
  every launch (was the driving stutter).
- `VICTORY_SKIP_PIPELINES`: skip list fixed so it also works in release builds; plus two water-light shaders that
  drew dark sea tiles on 32-lane cards (~15 ms of GPU time).
- `-Hooks` (`VICTORY_GPU_ONLY=1`, `VICTORY_KNOWN_WRITES=1`): faster memory hooks; normal play uses it.

**Picture:**
- DLSS Super Resolution through NVIDIA Streamline: `VICTORY_DLSS=1`,
  `VICTORY_DLSS_MODE=quality|balanced|performance`. No frame generation hooks. Night scenes are GPU-bound
  (30–50 ms of lights), which is why upscaling helps there.
- Floor reflection fix: `VICTORY_REFLECT_SCREEN=1`, `VICTORY_AMBIENT_REFLECT=0.5`
  (white glare on floors, glass, eyes).
- `VICTORY_NAN_GUARD_STORES=1`: NaN guard on float image stores too (changes translations: one long warm-up).
- `VICTORY_THIN=0` on purpose: it blurs on RTX 50 cards.

**In the code, being tested:**
- Recorder fixes: 8-byte-per-round address hash (on), per-thread texture cache
  (`VICTORY_TEXTURE_NEAR`, on), per-thread descriptor cache (`VICTORY_VIEW_NEAR=1`, off by default).
- GPU copy-back limit: `VICTORY_GPU_BACK_MAX_KB` (off unless set).

**Known open issues:** page pool mostly scattered (GPU reads only ~400 MB in place), white reflections with ray
tracing off, phone/radio/TV audio silent, garbled phone subtitles, green car paint.

**How we test:** one change at a time behind a switch; keep only what is faster *and* looks the same. Runs are
compared by draw-count buckets, warm frames only (no pipelines being made).

## Where it came from

Lineage of this fork:
[Marvisak/VIctory](https://github.com/Marvisak/VIctory) ->
[fxceless/victory-fork](https://github.com/fxceless/victory-fork) ->
[Op-lite/victory-scarlett](https://github.com/Op-lite/victory-scarlett) ->
[Yaekai/victory-scarlett-3070](https://github.com/Yaekai/victory-scarlett-3070) -> **VIcious Scarlett**.

Also thanks to ANYDEV (Vedant), [Neptune_VI](https://github.com/zm0kiemedia/Neptune_VI) (zm0kie) and Neptune dolberth.

NVIDIA's DLSS / Streamline runtime files are **not** in this repository: get them from
[NVIDIA-RTX/Streamline](https://github.com/NVIDIA-RTX/Streamline) releases and put the `bin\x64` DLLs in
`nvidia-sdk\Streamlineind`.
