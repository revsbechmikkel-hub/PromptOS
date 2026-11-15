# 🧠 PromptOS

> **Turn any Linux desktop into a private, offline-first AI workstation.**  
> A lightweight assistant setup tool (and soon an overlay) for Ubuntu & KDE Plasma, powered by [Ollama](https://ollama.com).

[![CI](https://github.com/revsbechmikkel-hub/PromptOS/actions/workflows/ci.yml/badge.svg)](https://github.com/revsbechmikkel-hub/PromptOS/actions/workflows/ci.yml)

> **🚧 Alpha:** PromptOS is early. The **installer and hardware-aware model picker work today** (see below). The floating `Alt + Space` overlay and the KDE integration are still being designed. PromptOS is a **companion for your existing Linux install** (not a separate OS), and we're looking for contributors!

---

## 🚀 Quick start

```bash
git clone https://github.com/revsbechmikkel-hub/PromptOS.git
cd PromptOS
./install.sh
```

Or without cloning:

```bash
curl -fsSL https://raw.githubusercontent.com/revsbechmikkel-hub/PromptOS/main/install.sh | bash
```

> 🔐 Piping a script into `bash` runs it with your permissions. If you'd rather read it first, download it, open it, then run it. It is a single readable file.

The installer will:

1. **Scan your hardware** (RAM, NVIDIA/AMD GPU and VRAM).
2. **Ask 3 quick questions** (what you'll use it for, speed vs. brainpower, auto-pick or browse).
3. **Pick a model that actually fits your machine**. It never suggests a 70B model for a 16 GB laptop.
4. **Install Ollama** (official installer) if it's missing, check disk space, start the service and **download the model**.

### Options

| Option | What it does |
|---|---|
| `-y`, `--yes` | No questions: use flags or defaults (chat, balanced). Good for scripts. |
| `--category chat\|coding\|reasoning\|vision` | Skip question 1 |
| `--speed fast\|balanced\|smart` | Skip question 2 (`smart` may spill into system RAM: smarter, slower) |
| `--model TAG` | Skip the quiz and install an exact Ollama model, e.g. `qwen3:8b` |
| `--list` | Show every model that fits this machine and exit |
| `--dry-run` | Show what would happen; change nothing |
| `--no-ollama-install` | Don't install Ollama; fail if it's missing |

```bash
./install.sh --yes --category coding --speed balanced   # unattended
./install.sh --list                                     # what fits my PC?
./install.sh --dry-run                                  # safe preview
```

### How the model is chosen

`models.json` holds a curated, best-first list per category (★ in `--list`) plus a longer "more" list. The installer estimates the memory you can safely use and picks the first recommended model that fits:

| Mode | GPU present | CPU only |
|---|---|---|
| `fast` | up to ~3 GB models | up to ~3 GB models |
| `balanced` | model fits in VRAM (minus ~1.5 GB headroom) | up to ~8B models |
| `smart` | largest model that fits in VRAM *or* RAM (partly offloaded to RAM) | largest that fits in RAM (slow!) |

Sizes are approximate Q4 downloads; real memory use is higher because of the context cache, which is why headroom is reserved.

---

## 💡 The Vision

**PromptOS** aims to make local, private AI effortless on Linux, with no complex terminal setup. Instead of reinstalling your OS, PromptOS integrates [Ollama](https://ollama.com) directly into your existing desktop workflow, so your personal assistant can help you write, code, summarize and answer questions, 100% offline and private.

### ✨ Features

| | Feature | Status |
|---|---|---|
| ✅ | **One-command installer** that sets up Ollama and pulls a model | Working |
| ✅ | **Smart hardware scan** (RAM, NVIDIA & AMD VRAM) with fit-based model selection | Working |
| ✅ | **Model quiz** across chat, coding, reasoning and vision (130+ models) | Working |
| ✅ | **Non-interactive mode**, dry-run and automated tests / CI | Working |
| ⌨️ | **Instant AI shortcut (`Alt + Space`)**: floating assistant overlay | Planned |
| 🎨 | **Native KDE Plasma integration** (widgets, system styling) | Planned |
| 🔒 | **Privacy by design**: zero telemetry, no accounts, everything local | Always |

---

## 🛠️ Tech stack

* **Target:** Ubuntu / Kubuntu / KDE Plasma (more distros later)
* **LLM backend:** Ollama
* **Installer:** Bash (+ a little Python for reading the catalog)
* **Overlay (planned):** Python (PyQt/QML) or a native Plasma widget

---

## 🧪 Development

```bash
shellcheck install.sh tests/test_picker.sh   # lint
python3 scripts/check_models.py              # validate models.json (offline)
python3 scripts/check_models.py --registry   # also verify every tag exists on Ollama
tests/test_picker.sh                         # hardware -> model regression tests
```

Pretend to be other hardware without owning it:

```bash
PROMPTOS_RAM_GB=32 PROMPTOS_VRAM_GB=12 ./install.sh --dry-run --yes --category coding
```

CI runs lint + tests on every push, and a **weekly registry check** that flags models that were renamed or removed upstream.

**Adding or changing models:** edit `models.json`. Put good, current models in `recommended` (best first, with a `gb` size). Everything else goes in `more` as a plain tag; its size is estimated from the tag (e.g. `:7b`).

---

## 🤝 Contributing

Want to help build a native-feeling local AI assistant for Linux? Good first areas:

* 🖥️ **Floating overlay UI & global hotkey**: a lightweight window that pops up with `Alt + Space` and talks to the local Ollama API.
* 📦 **Packaging**: `.deb` / AppImage.
* 🧪 **Testing on real hardware**: especially AMD GPUs, multi-GPU and low-RAM machines. Open an issue with the output of `./install.sh --dry-run`.
* 🗂️ **Model catalog**: keep `recommended` fresh as new models land.

👉 Head over to [Discussions](../../discussions) or [Issues](../../issues) to say hi.

---

## 🗺️ Roadmap

- [x] **Step 0:** Project vision and repository
- [x] **Step 1:** Installer: detects RAM/GPU, installs Ollama, picks and downloads a fitting model
- [x] **Step 2:** Tests, CI and a verifiable model catalog
- [ ] **Step 3:** Floating AI chat window triggered by a global shortcut (`Alt + Space`)
- [ ] **Step 4:** Package as `.deb` / AppImage for a `v0.1` release
- [ ] **Future:** KDE Plasma widget; optionally a pre-configured live ISO

---

*Disclaimer: PromptOS is an independent open-source project and is not affiliated with, endorsed by, or sponsored by Ollama Inc. or Canonical Ltd.*

*Built with ❤️ for open-source and digital privacy.*
