#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"
if ! command -v python3 >/dev/null 2>&1; then echo "Python 3 is required."; exit 1; fi
if ! python3 -c 'import tkinter' >/dev/null 2>&1; then
  echo "Tkinter is missing. On Ubuntu/Debian run: sudo apt install python3-tk"
  exit 1
fi
exec python3 -m promptos.main "$@"
