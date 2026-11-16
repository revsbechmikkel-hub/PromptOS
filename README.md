# PromptOS

PromptOS is a Linux desktop companion for private, local AI. It runs on your existing Linux desktop (it is **not** a replacement operating system) and connects to [Ollama](https://ollama.com).

## What's included in this build

- Guided first-run setup wizard
- Hardware detection for system RAM and NVIDIA/AMD VRAM
- Hardware-aware model suggestions based on the existing `models.json` catalog
- Local chat UI with conversation context
- Model download dialog using Ollama's local API
- Linux desktop launcher and uninstall script
- No telemetry, accounts, or cloud AI calls

## Requirements

- Linux (Ubuntu, Kubuntu, Debian recommended)
- Python 3.10+
- Tkinter (`python3-tk` on Ubuntu/Debian)
- Ollama for model downloads and AI chat (optional until you want to chat)

## Install

```bash
chmod +x install.sh launch.sh uninstall.sh
./install.sh
```

Then launch from your application menu or run:

```bash
~/.local/bin/promptos
```

For a portable run without installing:

```bash
./launch.sh
```

On Ubuntu/Debian, if Tkinter is missing:

```bash
sudo apt update
sudo apt install python3-tk
```

Install Ollama separately using its official Linux instructions: https://ollama.com/download/linux

## First run

The wizard scans hardware, asks what you use AI for, asks whether you prefer speed or capability, and suggests a model. It saves settings in `~/.config/promptos/settings.json`.

## Model manager

Open **Models** and enter an Ollama model tag, for example `qwen3:4b`. Downloads use the local Ollama API at `http://127.0.0.1:11434`. Set `OLLAMA_HOST` to use another local Ollama endpoint.

## Development

```bash
python3 -m unittest discover -s tests
python3 -m promptos.main
```

## Security and privacy

PromptOS talks to the Ollama service configured on your machine. Keep Ollama bound to localhost unless you intentionally need network access. Model downloads require internet; inference can run offline after a model has been downloaded. No telemetry is implemented.

## Current limitations

- The interface is a lightweight Tkinter desktop app, not yet a KDE Plasma-native widget.
- No global `Alt+Space` shortcut, AppImage, or `.deb` package yet.
- Vision models can be downloaded, but image attachment support in chat is not implemented yet.
- Model size estimates are approximate and do not guarantee fit for every context length or GPU/runtime combination.
- Model deletion, advanced model parameters, and persistent chat history are future work.

## License

See [LICENSE](LICENSE).
