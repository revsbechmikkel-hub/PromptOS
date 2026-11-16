#!/usr/bin/env bash
set -Eeuo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
echo "PromptOS Linux installer"
[[ "$(uname -s)" == Linux ]] || { echo "PromptOS currently supports Linux only."; exit 1; }
command -v python3 >/dev/null || { echo "Install Python 3 first."; exit 1; }
if ! python3 -c 'import tkinter' >/dev/null 2>&1; then
  echo "Tkinter is required."
  if command -v apt-get >/dev/null; then
    read -r -p "Install python3-tk using sudo apt? [y/N] " ans
    [[ "${ans,,}" == y || "${ans,,}" == yes ]] && sudo apt-get update && sudo apt-get install -y python3-tk
  else
    echo "Install your distribution's Python Tk package, then rerun."; exit 1
  fi
fi
mkdir -p "$HOME/.local/bin" "$HOME/.local/share/applications"
TARGET="$HOME/.local/share/promptos"
rm -rf "$TARGET"
mkdir -p "$TARGET"
cp -a "$ROOT/promptos" "$ROOT/models.json" "$TARGET/"
cat > "$HOME/.local/bin/promptos" <<EOF
#!/usr/bin/env bash
cd "$TARGET"
exec python3 -m promptos.main "\$@"
EOF
chmod +x "$HOME/.local/bin/promptos"
cat > "$HOME/.local/share/applications/promptos.desktop" <<EOF
[Desktop Entry]
Type=Application
Name=PromptOS
Comment=Private local AI assistant
Exec=$HOME/.local/bin/promptos
Icon=applications-science
Terminal=false
Categories=Utility;Development;
EOF
chmod +x "$HOME/.local/share/applications/promptos.desktop"
echo
echo "PromptOS installed. Start it with: $HOME/.local/bin/promptos"
echo "Ollama is optional for the UI but required for local model chat."
echo "Install Ollama from https://ollama.com/download/linux if needed."
