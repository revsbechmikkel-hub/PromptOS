# 🧠 PromptOS

> **Turn any Linux desktop into a private, offline-first AI workstation.**  
> A lightweight assistant overlay and setup tool for Ubuntu & KDE Plasma, powered by [Ollama](https://ollama.com).

> **🚧 Early Stage Notice:** This project has **just started**! **Zero lines of code have been written yet.** Based on great community feedback, we are focusing on building PromptOS as an **easy-to-install companion app/suite for existing Linux installations** (rather than maintaining a whole separate OS from scratch). We are looking for founding contributors to help build it!

---

## 💡 The Vision

**PromptOS** aims to make local, private Artificial Intelligence effortless on Linux—no complex terminal setup required. 

Instead of forcing users to reinstall their entire operating system, PromptOS will be a **clean, all-in-one package/script** that integrates [Ollama](https://ollama.com) directly into your existing desktop workflow. From the moment you install it, your personal AI assistant is ready to help you write, code, summarize documents, and answer questions—100% offline and private.

### ✨ Planned Features (The Goal)

* 🚀 **One-Click / One-Command Installer:** Automatically installs Ollama as a background service and sets up the desktop integration on Ubuntu / KDE Plasma.
* 🧠 **Smart Hardware Setup Wizard:** Detects your RAM and GPU (NVIDIA/AMD) during setup and recommends/downloads the best local AI model for your PC (e.g., Llama, Mistral, Gemma).
* ⌨️ **Instant AI Shortcut (`Alt + Space`):** Press a global hotkey anywhere in your desktop to summon a clean, floating AI assistant overlay.
* 🎨 **Native KDE Plasma Integration:** Clean desktop widgets and seamless system styling that feels like a built-in OS feature.
* 🔒 **Privacy by Design:** Zero telemetry, no required accounts, and all AI processing happens locally on your own hardware.

---

## 🛠️ Proposed Tech Stack

* **Target Environment:** Ubuntu / Kubuntu / KDE Plasma (with plans to support more distros later)
* **Local LLM Backend:** Ollama
* **Installer & Hardware Detection:** Bash / Python
* **Desktop UI / Overlay:** Python (PyQt/QML) or native KDE Plasma Widget

---

## 🤝 Looking for Co-Founders & Contributors!

**Want to help build a native-feeling local AI assistant for Linux from Day 1?**

As the project creator, I am leading the **vision, UI/UX ideas, testing, and community management**. Since I am not a programmer myself, I am looking for Linux enthusiasts, scripters, and developers who want to team up and write the very first lines of code together.

### How We Can Start Together:
* 💬 **Architecture & Planning:** Help decide the best framework for the floating chat overlay and installer.
* 🐚 **Bash / Python Installer Script:** Write a setup script that installs Ollama, checks RAM/GPU specs, and pulls a recommended model.
* 🖥️ **Floating Overlay UI & Hotkey:** Build a lightweight window that pops up with `Alt + Space` and talks to the local Ollama API.
* 🧪 **Testing & Feedback:** Test early scripts on Ubuntu/KDE setups and share ideas.

👉 **Head over to the [Discussions](../../discussions) or [Issues](../../issues) tab** to say hi and share your thoughts!

---

## 🗺️ Roadmap (Starting from Scratch)

- [x] **Step 0:** Define project vision, gather community feedback, and set up GitHub repository
- [ ] **Step 1:** Assemble a small team of interested contributors
- [ ] **Step 2:** Build a basic installer script (installs Ollama + detects GPU/RAM + downloads a model)
- [ ] **Step 3:** Create the floating AI chat window triggered by a global shortcut (`Alt + Space`)
- [ ] **Step 4:** Package as an easy installer (`.deb` / AppImage / install script) for `v0.1-alpha` release
- [ ] **Future Goal:** Optionally offer a pre-configured live ISO once the core software is solid

---

*Disclaimer: PromptOS is an independent open-source project and is not affiliated with, endorsed by, or sponsored by Ollama Inc. or Canonical Ltd.*

*Built with ❤️ for open-source and digital privacy.*


