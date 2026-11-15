#!/usr/bin/env bash

# ==============================================================================
# PromptOS - Smart Installer & Hardware Setup Wizard (v0.1-alpha prototype)
# ==============================================================================

set -e

echo "=========================================="
echo " 🧠 Welcome to the PromptOS Setup Wizard!"
echo "=========================================="
echo ""

# 1. Check if running on Linux
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "❌ Error: PromptOS is designed for Linux systems only."
    exit 1
fi

# 2. Detect System RAM (in GB)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
echo "🔍 Detected System RAM: ${TOTAL_RAM_GB} GB"

# 3. Detect GPU (NVIDIA / AMD / CPU-only)
GPU_TYPE="CPU"
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)
    GPU_TYPE="NVIDIA"
    echo "🎮 Detected NVIDIA GPU: ${GPU_NAME}"
elif lspci | grep -i -E "vga|3d" | grep -i "amd" &> /dev/null; then
    GPU_TYPE="AMD"
    echo "🎮 Detected AMD GPU"
else
    echo "💻 No dedicated NVIDIA/AMD GPU detected. Running in CPU mode."
fi

echo ""

# 4. Install Ollama if not already installed
if command -v ollama &> /dev/null; then
    echo "✅ Ollama is already installed!"
else
    echo "📦 Installing Ollama..."
    curl -fsSL https://ollama.com | sh
    echo "✅ Ollama installation complete!"
fi

echo ""

# 5. Recommend an AI Model based on hardware
RECOMMENDED_MODEL="llama3.2:1b"

if [[ "$GPU_TYPE" == "NVIDIA" || "$GPU_TYPE" == "AMD" ]] && [[ "$TOTAL_RAM_GB" -ge 16 ]]; then
    RECOMMENDED_MODEL="llama3.1:8b"
elif [[ "$TOTAL_RAM_GB" -ge 8 ]]; then
    RECOMMENDED_MODEL="llama3.2:3b"
else
    RECOMMENDED_MODEL="llama3.2:1b"
fi

echo "🤖 Based on your hardware, we recommend the model: ${RECOMMENDED_MODEL}"
read -p "Do you want to download ${RECOMMENDED_MODEL} now? (y/n): " CHOICE

if [[ "$CHOICE" == "y" || "$CHOICE" == "Y" ]]; then
    echo "⬇️ Downloading ${RECOMMENDED_MODEL} (this may take a few minutes)..."
    ollama pull "$RECOMMENDED_MODEL"
    echo "🎉 Model ${RECOMMENDED_MODEL} is ready!"
else
    echo "⏭️ Skipped model download. You can download one later using: ollama pull <model>"
fi

echo ""
echo "=========================================="
echo " 🚀 PromptOS Core Setup Complete!"
echo " Try running: ollama run ${RECOMMENDED_MODEL}"
echo "=========================================="
