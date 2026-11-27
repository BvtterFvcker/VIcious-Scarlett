# VIcious Scarlett

An Xbox Series emulator fork (Windows, NVIDIA) tuned to run **Grand Adventure of Robberies** on 8 GB NVIDIA cards,
with optional **DLSS** upscaling. Source only: you build it yourself.

**This repository contains no game files, code or assets.** You need your own dump of the game (the folder with
`game_scarlett_master.exe`). Not affiliated with or endorsed by the game's developer or publisher. GPL-3.0-or-later.

**How it works, what we changed and where it came from: [docs/VICIOUS-SCARLETT.md](docs/VICIOUS-SCARLETT.md).**

## Build

Install [Rust](https://rustup.rs) and the Visual Studio C++ build tools with a Windows SDK, then in this folder:

```powershell
cargo build --release --locked -p victory
```

For DLSS (optional): put NVIDIA's Streamline `bin\x64` DLLs from [NVIDIA-RTX/Streamline](https://github.com/NVIDIA-RTX/Streamline)
in `nvidia-sdk\Streamline\bin\x64`.

## Run

1. Double-click **`VIcious Scarlett.cmd`**. The first time, paste the path of `game_scarlett_master.exe` (or its folder).
2. Menu: **A** play without DLSS, **B** play with DLSS (Balanced), **W** only warm shaders/pipelines, **G** change game path.
3. When the game closes you're back at the menu.

Best with RAM + page file of 48 GB or more; with less, the launcher turns `VICTORY_POOL_COMMIT` off by itself.
The first launches stutter while pipelines are made. Logs: `runs\3070-<date>.log`. Cache and saves: `runs\cache`, `runs\data`.

## Credits

Built on [Op-lite/victory-scarlett](https://github.com/Op-lite/victory-scarlett), [fxceless/victory-fork](https://github.com/fxceless/victory-fork),
[Marvisak/VIctory](https://github.com/Marvisak/VIctory) and [Yaekai/victory-scarlett-3070](https://github.com/Yaekai/victory-scarlett-3070).
Thanks to ANYDEV, Neptune_VI and Neptune dolberth. Upstream notes: [README-upstream.md](README-upstream.md).
