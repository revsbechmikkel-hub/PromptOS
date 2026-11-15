#!/usr/bin/env bash

# ==============================================================================
# PromptOS - Smart Installer, Hardware Scanner & AI Model Quiz (v0.2-alpha)
# ==============================================================================

set -e

clear
echo "=========================================================="
echo " 🧠 Welcome to PromptOS - Smart Setup & AI Model Quiz!"
echo "=========================================================="
echo ""

# 1. Check OS & Dependencies
if [[ "$(uname -s)" != "Linux" ]]; then
    echo "❌ Error: PromptOS is designed for Linux systems only."
    exit 1
fi

if ! command -v python3 &> /dev/null; then
    echo "❌ Error: Python 3 is required to run the model quiz."
    exit 1
fi

# 2. Detect System Hardware (RAM & GPU)
TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))

GPU_TYPE="CPU"
VRAM_GB=0
if command -v nvidia-smi &> /dev/null; then
    GPU_NAME=$(nvidia-smi --query-gpu=name --format=csv,noheader | head -n 1)
    VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n 1)
    VRAM_GB=$((VRAM_MB / 1024))
    GPU_TYPE="NVIDIA ($GPU_NAME - ${VRAM_GB}GB VRAM)"
elif lspci | grep -i -E "vga|3d" | grep -i "amd" &> /dev/null; then
    GPU_TYPE="AMD Radeon GPU"
fi

echo "📊 HARDWARE SCAN COMPLETE:"
echo "   • System RAM : ${TOTAL_RAM_GB} GB"
echo "   • Graphics   : ${GPU_TYPE}"
echo ""

# Determine maximum safe hardware tier
MAX_TIER="ultra_light"
if [[ "$VRAM_GB" -ge 20 ]] || [[ "$TOTAL_RAM_GB" -ge 32 ]]; then
    MAX_TIER="heavy"
elif [[ "$VRAM_GB" -ge 6 ]] || [[ "$TOTAL_RAM_GB" -ge 12 ]]; then
    MAX_TIER="medium"
fi

# 3. Install Ollama if missing
if command -v ollama &> /dev/null; then
    echo "✅ Ollama engine is already installed."
else
    echo "📦 Installing Ollama engine..."
    curl -fsSL https://ollama.com | sh
    echo "✅ Ollama installed successfully!"
fi

echo ""
echo "=========================================================="
echo " 🎯 AI ASSISTANT QUIZ (100+ Models Supported)"
echo " Answer 3 quick questions to find your ideal local AI!"
echo "=========================================================="
echo ""

# Question 1: Primary Use Case
echo "1️⃣  What will you primarily use your AI assistant for?"
echo "   [1] Everyday Chat, Writing & Summarizing (General)"
echo "   [2] Programming, Debugging & Scripts (Coding)"
echo "   [3] Deep Logic, Math & Complex Problem Solving (Reasoning)"
echo "   [4] Analyzing Images & Screenshots (Vision)"
read -p "👉 Choose (1-4): " Q1

CATEGORY="chat_general"
case $Q1 in
    2) CATEGORY="coding" ;;
    3) CATEGORY="reasoning_math" ;;
    4) CATEGORY="vision_multimodal" ;;
    *) CATEGORY="chat_general" ;;
esac

echo ""

# Question 2: Speed vs. Intelligence
echo "2️⃣  What matters most to you?"
echo "   [1] Instant, lightning-fast replies (Smaller models)"
echo "   [2] Balanced speed and intelligence (Recommended for your hardware)"
echo "   [3] Maximum brainpower, even if replies are slower (Larger models)"
read -p "👉 Choose (1-3): " Q2

SELECTED_TIER="$MAX_TIER"
if [[ "$Q2" == "1" ]]; then
    SELECTED_TIER="ultra_light"
elif [[ "$Q2" == "3" ]]; then
    if [[ "$MAX_TIER" == "ultra_light" ]]; then
        echo "⚠️  Note: Your hardware has limited RAM/VRAM, so we'll cap at 'medium' to prevent crashes."
        SELECTED_TIER="medium"
    else
        SELECTED_TIER="heavy"
    fi
fi

# Vision models don't have an ultra_light tier in our catalog
if [[ "$CATEGORY" == "vision_multimodal" && "$SELECTED_TIER" == "ultra_light" ]]; then
    SELECTED_TIER="medium"
fi

echo ""

# Question 3: Browse full list or pick top recommendation?
echo "3️⃣  How would you like to pick your model?"
echo "   [1] Give me the #1 best recommendation automatically"
echo "   [2] Show me all matching models from the 100+ catalog so I can choose"
read -p "👉 Choose (1-2): " Q3

echo ""

# Use embedded Python to query models.json cleanly
CHOSEN_MODEL=$(python3 -c "
import json, sys, os

if not os.path.exists('models.json'):
    print('llama3.2:3b')
    sys.exit(0)

with open('models.json') as f:
    data = json.load(f)

models = data['categories'].get('$CATEGORY', {}).get('$SELECTED_TIER', ['llama3.2:3b'])
print(models[0])
")

if [[ "$Q3" == "2" ]]; then
    echo "📚 Available models matching your quiz & hardware (${CATEGORY} -> ${SELECTED_TIER}):"
    python3 -c "
import json
with open('models.json') as f:
    data = json.load(f)
models = data['categories'].get('$CATEGORY', {}).get('$SELECTED_TIER', [])
for i, m in enumerate(models, 1):
    print(f'   [{i}] {m}')
"
    echo ""
    read -p "👉 Enter the number of the model you want to install (default 1): " MODEL_IDX
    MODEL_IDX=${MODEL_IDX:-1}
    CHOSEN_MODEL=$(python3 -c "
import json
with open('models.json') as f:
    data = json.load(f)
models = data['categories'].get('$CATEGORY', {}).get('$SELECTED_TIER', ['llama3.2:3b'])
idx = int('$MODEL_IDX') - 1
print(models[idx] if 0 <= idx < len(models) else models[0])
")
fi

echo "=========================================================="
echo " 🏆 Quiz Result: Your ideal AI model is -> ${CHOSEN_MODEL}"
echo "=========================================================="
read -p "⬇️  Download and activate ${CHOSEN_MODEL} now? (y/n): " CONFIRM

if [[ "$CONFIRM" == "y" || "$CONFIRM" == "Y" ]]; then
    echo "⏳ Pulling ${CHOSEN_MODEL} via Ollama..."
    ollama pull "$CHOSEN_MODEL"
    echo ""
    echo "🎉 Success! PromptOS is ready with ${CHOSEN_MODEL}."
    echo "💡 Type 'ollama run ${CHOSEN_MODEL}' anytime to start chatting!"
else
    echo "⏭️  Download skipped. Run 'ollama pull ${CHOSEN_MODEL}' whenever you're ready."
fi

