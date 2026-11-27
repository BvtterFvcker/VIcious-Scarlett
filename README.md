# VIcious Scarlett

**by [BvtterFvcker](https://github.com/BvtterFvcker)**

My fork of the Scarlett line of Xbox Series emulators (Windows, NVIDIA), tuned to run **Grand Adventure of Robberies**
on 8 GB NVIDIA cards, with optional **DLSS** upscaling. I measured every setting, kept only what was faster and looked
the same, and added DLSS, the in-place memory path and the reflection fix. Source only: you build it yourself.

**This repository contains no game files, code or assets.** You need your own dump of the game (the folder with
`game_scarlett_master.exe`). Not affiliated with or endorsed by the game's developer or publisher. GPL-3.0-or-later.

How it works, what I changed and where it came from: **[docs/VICIOUS-SCARLETT.md](docs/VICIOUS-SCARLETT.md)**.

## Straight up: what to expect

- **It's slow.** On my RTX 5060 Laptop (Ryzen 9 8940HX, 24 GB RAM) it runs about **8–16 fps** of real frames
  (≈64 ms a frame in light scenes, ≈128 ms in heavy ones). Night scenes are heavier on the GPU, daytime on the CPU.
  A friend's Ryzen 9850X3D + RTX 5080 gets about 20–26 fps. The goal is a stable 20+.
- **It stutters at first.** Shader pipelines get compiled while you play until they're warm (menu **W** helps).
- **Not everything works:** phone/radio/TV audio is silent, phone subtitles are garbled, some car paint is green,
  reflections can be too white, ray tracing is off.
- **This code is newer than what I last played.** Two changes are in here but not tested yet: per-thread
  recorder caches (texture cache on by default) and a GPU copy-back limit (off unless set). Your numbers may
  differ from mine; that's what the reports are for.
- **DLSS (menu B) is new** and still being checked; if it looks wrong, use **A**.
- It's an experiment, not a finished product. No support promises; issues with a report are welcome.

## Quick start (about 20 minutes the first time)

**You need:** Windows 10/11 · an NVIDIA RTX card with a current driver · your own game dump · ~5 GB free disk.
Best: RAM + page file of 48 GB or more (Windows: *Advanced system settings → Performance → Advanced →
Virtual memory*, custom size 40000–48000 MB, reboot). With less it still runs; the launcher adapts.

1. **Install the build tools (once):**
   - [Rust](https://rustup.rs) (default options).
   - [Visual Studio Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/) with
     *Desktop development with C++* (includes the Windows SDK).
2. **Get the code:** *Code → Download ZIP* and unzip, or `git clone https://github.com/BvtterFvcker/VIcious-Scarlett`.
   Use a folder you can write to (not Program Files).
3. **Build:** open PowerShell in that folder and run:
   ```powershell
   cargo build --release --locked -p victory
   ```
   It's done when it prints `Finished` and `target\release\victory.exe` exists.
4. **DLSS (optional):** download a release of [NVIDIA-RTX/Streamline](https://github.com/NVIDIA-RTX/Streamline) and copy
   its `bin\x64` DLLs into `nvidia-sdk\Streamline\bin\x64` (create the folders).
5. **Play:** double-click **`VIcious Scarlett.cmd`**. The first time, paste the path of `game_scarlett_master.exe`
   (or its folder). Then pick:

   | Key | What it does |
   |---|---|
   | **A** | Play without DLSS |
   | **B** | Play with DLSS (Balanced) — needs step 4 |
   | **W** | Only warm shaders/pipelines (no game). Do this once first for less stutter; it resumes if stopped |
   | **R** | Make a performance report of your last run (see below) |
   | **G** | Change the game path |
   | **Q** | Quit |

   When the game closes you're back at the menu. Nothing relaunches by itself.

The first launches stutter while pipelines are made and the NVIDIA driver fills its cache; it gets smoother each run.
Logs: `runs\3070-<date>.log`. Cache: `%LOCALAPPDATA%\VIcious-Scarlett\cache` (safe to delete).
Saves: `%LOCALAPPDATA%\VIcious-Scarlett\data` (keep).

## Testing: send me (BvtterFvcker) your performance numbers

I'm collecting numbers from different PCs. Please:

1. Warm once (menu **W**), then play **10+ minutes** with **A** (and, if you can, another run with **B** for DLSS).
   Walk, drive, go indoors and outdoors, day and night.
2. Close the game, then pick **R** in the menu. It reads your newest log and makes a short report:
   your CPU, GPU, driver, RAM + page file, DLSS on/off, and the frame time in groups of draws per frame
   (only smooth "warm" frames count, so different PCs compare fairly).
3. The report is copied to your clipboard and saved as `runs\report-<date>.txt`. Paste it in an
   [issue on this repo](https://github.com/BvtterFvcker/VIcious-Scarlett/issues/new) with where you were and anything
   that looked wrong. I get every one. Nothing is sent automatically; only what you paste.

The report holds no personal info: only hardware names, Windows version and frame times.

## For AI assistants helping someone set this up

Follow these facts exactly; don't guess other paths or flags.

- **Prerequisites check:** `rustc --version` and `cargo --version` must work; the MSVC linker comes from the
  Visual Studio Build Tools ("Desktop development with C++"). Toolchain is pinned in `rust-toolchain.toml`.
- **Build command:** `cargo build --release --locked -p victory` from the repo root → `target\release\victory.exe`.
  (Diagnostics build, optional: `cargo build --locked --profile diag -p victory --features diagnostics` → `target\diag\`.)
- **Launch chain:** `VIcious Scarlett.cmd` → `scripts\play-3070-launcher.ps1 -Game <path to game_scarlett_master.exe>
  -Prewarm -Hooks [-Extra "NAME=VALUE;NAME=VALUE"]`. The .cmd stores the game path in `game-path.txt` and sets
  `VICTORY_CACHE_DIR=%LOCALAPPDATA%\VIcious-Scarlett\cache`, `VICTORY_DATA_DIR=%LOCALAPPDATA%\VIcious-Scarlett\data`.
  Never put cache or saves inside the repo: the asset policy refuses game-derived data in the source tree
  ("refusing to use … inside the VIctory source tree"). Logs stay in `runs\`.
- **Settings** are environment variables `VICTORY_*`, set in the `$set` table of `scripts\play-3070-launcher.ps1`.
  DLSS: `VICTORY_DLSS=1`, `VICTORY_DLSS_MODE=quality|balanced|performance`; DLL folder: `VICTORY_STREAMLINE_DIR`
  (default `nvidia-sdk\Streamline\bin\x64`).
- **Memory:** `VICTORY_POOL_COMMIT=1` needs RAM + page file ≥ ~48 GB; the .cmd sets it to 0 automatically below that.
- **Only one `victory.exe` may run**; the script refuses a second. Close it before rebuilding.
- **Never** download or share game files; the user must supply their own dump.
- **Troubleshooting:** "Release binary not found" → build step not done. "Game not found" → menu **G**.
  Crash at start → raise the page file. Black/flickering world early on → pipelines still compiling (menu **W**).
  Read the newest `runs\3070-*.log` (UTF-16) for errors.

## Credits

Built on [Op-lite/victory-scarlett](https://github.com/Op-lite/victory-scarlett), [fxceless/victory-fork](https://github.com/fxceless/victory-fork),
[Marvisak/VIctory](https://github.com/Marvisak/VIctory) and [Yaekai/victory-scarlett-3070](https://github.com/Yaekai/victory-scarlett-3070).
Thanks to ANYDEV, Neptune_VI and Neptune dolberth. Upstream notes: [README-upstream.md](README-upstream.md).
