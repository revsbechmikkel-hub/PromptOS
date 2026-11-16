#!/usr/bin/env bash
set -euo pipefail
rm -rf "$HOME/.local/share/promptos"
rm -f "$HOME/.local/bin/promptos" "$HOME/.local/share/applications/promptos.desktop"
echo "PromptOS application removed. User settings in ~/.config/promptos were kept."
