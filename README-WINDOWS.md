# PromptOS for Windows 10/11

This is the Windows desktop build of PromptOS 0.4.0. It uses the same local Tkinter interface and setup wizard as the Linux build, with Windows-aware RAM/GPU detection and settings stored in `%APPDATA%\PromptOS`.

## Build the Windows app

The Windows executable must be built on Windows (PyInstaller does not cross-compile Windows executables from Linux).

1. Install **Python 3.10+** from https://www.python.org/downloads/windows/ and enable **Add Python to PATH**.
2. Optional, for a click-through installer: install **Inno Setup 6** from https://jrsoftware.org/isdl.php.
3. Extract the whole PromptOS folder.
4. Double-click `build_windows.bat`.

The script creates `dist\PromptOS.exe`. If Inno Setup is installed and `ISCC.exe` is on PATH, it also creates `installer-output\PromptOS-Setup.exe`.

## Run from source

Double-click `run_windows.bat`, or run `py -3 -m promptos.main` from this folder.

## Ollama

PromptOS is the desktop client; Ollama is the local model runtime and is installed separately. Install it from https://ollama.com/download/windows. Start Ollama, open PromptOS, use the setup wizard, then use **Models** to download a model (for example `qwen3:4b`). Model downloads require internet; local inference can work offline after download.

## Notes

- Supported target: Windows 10/11, 64-bit, Python 3.10+ for source/build.
- The setup wizard estimates model fit from detected system RAM and graphics memory. Estimates are approximate.
- NVIDIA VRAM is read from `nvidia-smi` when available. Other Windows graphics adapters use the memory value exposed by the Windows video-controller driver, which may be shared or approximate.
- No telemetry or cloud AI service is included. Ollama is contacted at `http://127.0.0.1:11434` by default.
- This build does not yet include an automatic Ollama installer, native Windows global hotkey, image attachments, or persistent chat history.
