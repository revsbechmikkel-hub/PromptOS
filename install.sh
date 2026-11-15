#!/usr/bin/env bash
# ==============================================================================
# PromptOS - Smart installer, hardware scanner & AI model quiz (v0.3-alpha)
#
#   Interactive:      ./install.sh
#   One-liner:        curl -fsSL https://raw.githubusercontent.com/revsbechmikkel-hub/PromptOS/main/install.sh | bash
#   Non-interactive:  ./install.sh --yes --category coding --speed balanced
#   Preview only:     ./install.sh --dry-run
#
# Run `./install.sh --help` for all options.
# ==============================================================================

set -Eeuo pipefail

readonly VERSION="0.3-alpha"
readonly RAW_BASE="https://raw.githubusercontent.com/revsbechmikkel-hub/PromptOS/main"
readonly OLLAMA_INSTALL_URL="https://ollama.com/install.sh"

ASSUME_YES=0
DRY_RUN=0
LIST_ONLY=0
INSTALL_OLLAMA=1
OPT_CATEGORY=""
OPT_SPEED=""
OPT_MODEL=""

TMP_FILES=()
cleanup() {
    if [[ ${#TMP_FILES[@]} -gt 0 ]]; then
        rm -f "${TMP_FILES[@]}"
    fi
}
trap cleanup EXIT

info() { printf '%s\n' "$*"; }
warn() { printf '⚠️  %s\n' "$*" >&2; }
die()  { printf '❌ %s\n' "$*" >&2; exit 1; }

usage() {
    cat <<'EOF'
PromptOS installer

Usage: install.sh [options]

  -y, --yes               Never ask questions; use flags or sensible defaults
      --category NAME     chat | coding | reasoning | vision   (default: chat)
      --speed MODE        fast | balanced | smart              (default: balanced)
      --model TAG         Skip the quiz and install this exact Ollama model
      --list              List the models that fit this machine, then exit
      --dry-run           Show what would happen without changing anything
      --no-ollama-install Do not install Ollama (fail if it is missing)
  -h, --help              Show this help
  -V, --version           Show the version

Environment overrides (useful for testing other hardware):
  PROMPTOS_RAM_GB, PROMPTOS_VRAM_GB, PROMPTOS_MODELS_JSON
EOF
}

# ------------------------------------------------------------------------------
# Argument parsing
# ------------------------------------------------------------------------------
need_arg() { [[ $# -ge 2 && -n "$2" ]] || die "Option $1 needs a value (see --help)."; }

while [[ $# -gt 0 ]]; do
    case "$1" in
        -y|--yes)            ASSUME_YES=1 ;;
        --dry-run)           DRY_RUN=1 ;;
        --list)              LIST_ONLY=1 ;;
        --no-ollama-install) INSTALL_OLLAMA=0 ;;
        --category)          need_arg "$@"; OPT_CATEGORY="$2"; shift ;;
        --speed)             need_arg "$@"; OPT_SPEED="$2"; shift ;;
        --model)             need_arg "$@"; OPT_MODEL="$2"; shift ;;
        -h|--help)           usage; exit 0 ;;
        -V|--version)        echo "PromptOS installer ${VERSION}"; exit 0 ;;
        *)                   usage >&2; die "Unknown option: $1" ;;
    esac
    shift
done

normalize_category() {
    case "${1,,}" in
        chat|general|chat_general)             echo "chat_general" ;;
        coding|code)                           echo "coding" ;;
        reasoning|math|reasoning_math)         echo "reasoning_math" ;;
        vision|multimodal|vision_multimodal)   echo "vision_multimodal" ;;
        *) return 1 ;;
    esac
}

normalize_speed() {
    case "${1,,}" in
        fast|1)      echo "fast" ;;
        balanced|2)  echo "balanced" ;;
        smart|3)     echo "smart" ;;
        *) return 1 ;;
    esac
}

CATEGORY=""
SPEED=""
if [[ -n "$OPT_CATEGORY" ]]; then
    CATEGORY="$(normalize_category "$OPT_CATEGORY")" || die "Unknown category '$OPT_CATEGORY' (use chat, coding, reasoning or vision)."
fi
if [[ -n "$OPT_SPEED" ]]; then
    SPEED="$(normalize_speed "$OPT_SPEED")" || die "Unknown speed '$OPT_SPEED' (use fast, balanced or smart)."
fi

# ------------------------------------------------------------------------------
# Terminal input (works even when the script itself is piped into bash)
# ------------------------------------------------------------------------------
TTY_IN=""
if [[ $ASSUME_YES -eq 0 ]]; then
    if [[ -t 0 ]]; then
        TTY_IN="/dev/stdin"
    elif { : </dev/tty; } 2>/dev/null; then
        TTY_IN="/dev/tty"
    fi
fi

# ask VAR "prompt" "default"
ask() {
    local __var="$1" __prompt="$2" __default="${3:-}" __reply=""
    if [[ $ASSUME_YES -eq 1 ]]; then
        printf -v "$__var" '%s' "$__default"
        return 0
    fi
    [[ -n "$TTY_IN" ]] || die "No terminal available for questions. Re-run with --yes (and optionally --category/--speed/--model)."
    IFS= read -r -p "$__prompt" __reply <"$TTY_IN" || __reply=""
    printf -v "$__var" '%s' "${__reply:-$__default}"
}

# choose VAR "prompt" MIN MAX DEFAULT
choose() {
    local __out="$1" __prompt="$2" __min="$3" __max="$4" __default="$5" __v=""
    while true; do
        ask __v "$__prompt" "$__default"
        if [[ "$__v" =~ ^[0-9]+$ ]] && (( __v >= __min && __v <= __max )); then
            printf -v "$__out" '%s' "$__v"
            return 0
        fi
        [[ $ASSUME_YES -eq 0 ]] || die "Invalid default value '$__v'."
        warn "Please enter a number between ${__min} and ${__max}."
    done
}

# confirm "prompt"  -> returns 0 for yes
confirm() {
    local __a=""
    ask __a "$1 [Y/n]: " "y"
    [[ "${__a,,}" == "y" || "${__a,,}" == "yes" ]]
}

# ------------------------------------------------------------------------------
# Banner & prerequisites
# ------------------------------------------------------------------------------
echo "=========================================================="
echo " 🧠 PromptOS ${VERSION} - Smart Setup & AI Model Quiz"
echo "=========================================================="
echo ""

[[ "$(uname -s)" == "Linux" ]] || die "PromptOS is designed for Linux systems only."
command -v python3 >/dev/null 2>&1 || die "Python 3 is required (sudo apt install python3)."

# ------------------------------------------------------------------------------
# Hardware detection
# ------------------------------------------------------------------------------
RAM_GB="0"
VRAM_GB="0"
GPU_DESC="none detected (CPU only)"

detect_ram() {
    if [[ -n "${PROMPTOS_RAM_GB:-}" ]]; then
        RAM_GB="$PROMPTOS_RAM_GB"
        return 0
    fi
    RAM_GB="$(awk '/^MemTotal:/ {printf "%.1f", $2/1048576}' /proc/meminfo)"
}

detect_gpu() {
    if [[ -n "${PROMPTOS_VRAM_GB:-}" ]]; then
        VRAM_GB="$PROMPTOS_VRAM_GB"
        if awk -v v="$VRAM_GB" 'BEGIN {exit !(v > 0)}'; then
            GPU_DESC="override (${VRAM_GB} GB VRAM)"
        fi
        return 0
    fi

    local out="" name="" count="" total=0 f dev bytes

    # NVIDIA (sum VRAM over all cards; Ollama can split a model across them)
    if command -v nvidia-smi >/dev/null 2>&1; then
        if out="$(nvidia-smi --query-gpu=name,memory.total --format=csv,noheader,nounits 2>/dev/null)" && [[ -n "$out" ]]; then
            VRAM_GB="$(awk -F', *' '{s+=$2} END {printf "%.1f", s/1024}' <<<"$out")"
            name="$(head -n 1 <<<"$out" | cut -d, -f1)"
            count="$(wc -l <<<"$out" | tr -d ' ')"
            if [[ "$count" -gt 1 ]]; then
                GPU_DESC="NVIDIA ${name} (x${count}) - ${VRAM_GB} GB VRAM"
            else
                GPU_DESC="NVIDIA ${name} - ${VRAM_GB} GB VRAM"
            fi
            return 0
        fi
    fi

    # AMD (read dedicated VRAM from sysfs; no extra tools needed)
    for f in /sys/class/drm/card[0-9]*/device/mem_info_vram_total; do
        [[ -r "$f" ]] || continue
        dev="$(dirname "$f")"
        [[ "$(cat "$dev/vendor" 2>/dev/null || true)" == "0x1002" ]] || continue
        bytes="$(cat "$f" 2>/dev/null || echo 0)"
        total=$(( total + bytes ))
    done
    if (( total >= 2147483648 )); then
        VRAM_GB="$(awk -v b="$total" 'BEGIN {printf "%.1f", b/1073741824}')"
        GPU_DESC="AMD Radeon - ${VRAM_GB} GB VRAM (GPU acceleration depends on ROCm support)"
        return 0
    fi

    if command -v lspci >/dev/null 2>&1 && lspci 2>/dev/null | grep -Ei "vga|3d" | grep -qi "amd\|radeon"; then
        GPU_DESC="AMD/integrated GPU (VRAM unknown, sizing for CPU)"
    fi
    return 0
}

detect_ram
detect_gpu

echo "📊 HARDWARE SCAN COMPLETE:"
echo "   • System RAM : ${RAM_GB} GB"
echo "   • Graphics   : ${GPU_DESC}"
echo ""

# ------------------------------------------------------------------------------
# Locate models.json (next to this script, or download it for curl | bash)
# ------------------------------------------------------------------------------
MODELS_JSON="${PROMPTOS_MODELS_JSON:-}"
if [[ -z "$MODELS_JSON" ]]; then
    self="${BASH_SOURCE[0]:-}"
    if [[ -n "$self" && -f "$self" && -f "$(dirname "$self")/models.json" ]]; then
        MODELS_JSON="$(dirname "$self")/models.json"
    else
        command -v curl >/dev/null 2>&1 || die "curl is required to download the model catalog (sudo apt install curl)."
        MODELS_JSON="$(mktemp)"
        TMP_FILES+=("$MODELS_JSON")
        info "⬇️  Downloading model catalog..."
        curl -fsSL "${RAW_BASE}/models.json" -o "$MODELS_JSON" || die "Could not download models.json from ${RAW_BASE}."
    fi
fi
[[ -f "$MODELS_JSON" ]] || die "Model catalog not found: $MODELS_JSON"

# ------------------------------------------------------------------------------
# Model selection (pure data logic lives in Python; arguments come via argv,
# never by splicing shell variables into code)
# ------------------------------------------------------------------------------
# Prints: line 1 = "BUDGET<TAB>gb"; then "tag<TAB>gb<TAB>recommended|more" for every
# model that fits; or a single "NOFIT<TAB>tag<TAB>gb" line when nothing fits.
pick_models() {
    python3 -I - "$MODELS_JSON" "$1" "$2" "$RAM_GB" "$VRAM_GB" <<'PY'
import json, re, sys

path, category, mode, ram, vram = sys.argv[1:6]
ram, vram = float(ram), float(vram)

with open(path, encoding="utf-8") as fh:
    data = json.load(fh)
if data.get("schema") != 2:
    sys.exit("models.json has an unsupported format (expected schema 2). "
             "Update install.sh and models.json together.")
cat = data.get("categories", {}).get(category)
if cat is None:
    sys.exit("unknown category: " + category)


def estimate_gb(tag):
    """Rough Q4 download size from the parameter count in the tag."""
    part = tag.split(":", 1)[1] if ":" in tag else ""
    m = re.search(r"(\d+)x(\d+(?:\.\d+)?)b", part)
    if m:
        return int(m.group(1)) * float(m.group(2)) * 0.6 + 0.4
    m = re.search(r"(?<![\w.])(\d+(?:\.\d+)?)([bm])(?![a-z0-9])", part)
    if not m:
        return None
    params = float(m.group(1)) / (1000 if m.group(2) == "m" else 1)
    return params * 0.6 + 0.4


entries, seen = [], set()
for e in cat.get("recommended", []):
    if e["tag"] not in seen:
        seen.add(e["tag"])
        entries.append((e["tag"], float(e.get("gb") or estimate_gb(e["tag"]) or 0), "recommended"))
for tag in cat.get("more", []):
    gb = estimate_gb(tag)
    if tag not in seen and gb is not None:
        seen.add(tag)
        entries.append((tag, gb, "more"))

# Memory budgets (GB). Leave room for the OS and the context (KV) cache.
ram_budget = max(0.0, (ram - 4.0) * 0.7)
vram_budget = max(0.0, vram - 1.5) if vram >= 2 else 0.0
if vram_budget > 0:
    balanced = vram_budget                  # whole model on the GPU = fast
    smart = max(vram_budget, ram_budget)    # spill into RAM = slower but smarter
else:
    balanced = min(ram_budget, 6.0)         # CPU-only: keep to ~8B models
    smart = ram_budget
budget = {"fast": min(balanced, 3.0), "balanced": balanced, "smart": smart}[mode]

fit = [e for e in entries if e[1] <= budget]
if not fit:
    pool = [e for e in entries if e[2] == "recommended"] or entries
    tag, gb, _ = min(pool, key=lambda e: e[1])
    print("NOFIT\t%s\t%.1f" % (tag, gb))
else:
    print("BUDGET\t%.1f" % budget)
    for tag, gb, section in fit:
        print("%s\t%.1f\t%s" % (tag, gb, section))
PY
}

MODEL_TAGS=()
MODEL_GBS=()
MODEL_SECTIONS=()
BUDGET_GB=""
NOFIT=0

# load_models CATEGORY MODE -> fills MODEL_* arrays
load_models() {
    local out tag gb section
    out="$(pick_models "$1" "$2")" || die "Could not read the model catalog ($MODELS_JSON)."
    MODEL_TAGS=(); MODEL_GBS=(); MODEL_SECTIONS=(); NOFIT=0
    while IFS=$'\t' read -r tag gb section; do
        [[ -n "$tag" ]] || continue
        case "$tag" in
            BUDGET) BUDGET_GB="$gb" ;;
            # "NOFIT<TAB>tag<TAB>gb" is read as tag=NOFIT, gb=<real tag>, section=<real gb>
            NOFIT)  NOFIT=1; MODEL_TAGS+=("$gb"); MODEL_GBS+=("$section"); MODEL_SECTIONS+=("recommended") ;;
            *)      MODEL_TAGS+=("$tag"); MODEL_GBS+=("$gb"); MODEL_SECTIONS+=("$section") ;;
        esac
    done <<<"$out"
    return 0
}

# first_recommended -> index of the first "recommended" model that fits (or 0)
first_recommended() {
    local i
    for i in "${!MODEL_TAGS[@]}"; do
        if [[ "${MODEL_SECTIONS[$i]}" == "recommended" ]]; then
            echo "$i"
            return 0
        fi
    done
    echo 0
}

print_model_list() {
    local i
    for i in "${!MODEL_TAGS[@]}"; do
        printf '   [%2d] %-34s ~%5s GB %s\n' "$((i + 1))" "${MODEL_TAGS[$i]}" "${MODEL_GBS[$i]}" \
            "$([[ "${MODEL_SECTIONS[$i]}" == "recommended" ]] && echo "★" || echo "")"
    done
}

# ------------------------------------------------------------------------------
# --list: show what fits and exit (no questions, nothing installed)
# ------------------------------------------------------------------------------
if [[ $LIST_ONLY -eq 1 ]]; then
    for c in ${CATEGORY:-chat_general coding reasoning_math vision_multimodal}; do
        load_models "$c" "${SPEED:-smart}"
        echo "📚 ${c} (memory budget ~${BUDGET_GB:-0} GB, ★ = recommended):"
        if [[ $NOFIT -eq 1 ]]; then
            echo "   Nothing fits comfortably; smallest option: ${MODEL_TAGS[0]} (~${MODEL_GBS[0]} GB)"
        else
            print_model_list
        fi
        echo ""
    done
    exit 0
fi

# ------------------------------------------------------------------------------
# The quiz (skipped when flags or --model already answer the questions)
# ------------------------------------------------------------------------------
CHOSEN_MODEL=""
CHOSEN_GB=""

if [[ -n "$OPT_MODEL" ]]; then
    CHOSEN_MODEL="$OPT_MODEL"
else
    if [[ $ASSUME_YES -eq 0 ]]; then
        echo "=========================================================="
        echo " 🎯 AI ASSISTANT QUIZ - find your ideal local AI in 3 questions"
        echo "=========================================================="
        echo ""
    fi

    if [[ -z "$CATEGORY" ]]; then
        echo "1️⃣  What will you primarily use your AI assistant for?"
        echo "   [1] Everyday chat, writing & summarizing"
        echo "   [2] Programming, debugging & scripts"
        echo "   [3] Deep logic, math & complex problem solving"
        echo "   [4] Analyzing images & screenshots"
        choose Q1 "👉 Choose (1-4) [1]: " 1 4 1
        case "$Q1" in
            2) CATEGORY="coding" ;;
            3) CATEGORY="reasoning_math" ;;
            4) CATEGORY="vision_multimodal" ;;
            *) CATEGORY="chat_general" ;;
        esac
        echo ""
    fi
    [[ -n "$CATEGORY" ]] || CATEGORY="chat_general"

    if [[ -z "$SPEED" ]]; then
        echo "2️⃣  What matters most to you?"
        echo "   [1] Instant replies (small, fast models)"
        echo "   [2] Balanced speed and intelligence (recommended)"
        echo "   [3] Maximum brainpower, even if replies are slower (largest model your PC can hold)"
        choose Q2 "👉 Choose (1-3) [2]: " 1 3 2
        SPEED="$(normalize_speed "$Q2")"
        echo ""
    fi
    [[ -n "$SPEED" ]] || SPEED="balanced"

    load_models "$CATEGORY" "$SPEED"

    if [[ $NOFIT -eq 1 ]]; then
        warn "This machine has very little free memory. The smallest option is ${MODEL_TAGS[0]} (~${MODEL_GBS[0]} GB); expect slow replies."
        idx=0
    else
        idx="$(first_recommended)"
    fi

    # Question 3 only matters if there is more than one candidate.
    if [[ ${#MODEL_TAGS[@]} -gt 1 && $ASSUME_YES -eq 0 ]]; then
        echo "3️⃣  How would you like to pick your model?"
        echo "   [1] Use the best recommendation: ${MODEL_TAGS[$idx]} (~${MODEL_GBS[$idx]} GB)"
        echo "   [2] Show me everything that fits this PC and let me choose"
        choose Q3 "👉 Choose (1-2) [1]: " 1 2 1
        echo ""
        if [[ "$Q3" == "2" ]]; then
            echo "📚 Models that fit (${CATEGORY}, ${SPEED}; ★ = recommended, sizes are approximate):"
            print_model_list
            echo ""
            pick=1
            choose pick "👉 Enter the number of the model to install [$((idx + 1))]: " 1 "${#MODEL_TAGS[@]}" "$((idx + 1))"
            idx=$((pick - 1))
        fi
    fi

    CHOSEN_MODEL="${MODEL_TAGS[$idx]}"
    CHOSEN_GB="${MODEL_GBS[$idx]}"
fi

echo "=========================================================="
echo " 🏆 Selected model: ${CHOSEN_MODEL}${CHOSEN_GB:+ (~${CHOSEN_GB} GB download)}"
echo "=========================================================="

# ------------------------------------------------------------------------------
# Ollama: install (if needed) and make sure the server is running
# ------------------------------------------------------------------------------
ollama_base() {
    local base="${OLLAMA_HOST:-127.0.0.1:11434}"
    [[ "$base" == http* ]] || base="http://${base}"
    echo "$base"
}

ollama_up() {
    curl -fsS --max-time 2 "$(ollama_base)/api/version" >/dev/null 2>&1
}

ensure_ollama_running() {
    ollama_up && return 0
    info "🔌 Starting the Ollama service..."
    if command -v systemctl >/dev/null 2>&1; then
        systemctl start ollama 2>/dev/null || sudo -n systemctl start ollama 2>/dev/null || true
    fi
    if ! ollama_up; then
        local log
        log="$(mktemp)"
        TMP_FILES+=("$log")
        nohup ollama serve >"$log" 2>&1 &
    fi
    local i
    for i in $(seq 1 30); do
        ollama_up && return 0
        sleep 1
    done
    die "Ollama did not start. Try 'ollama serve' in another terminal, then re-run this script."
}

if command -v ollama >/dev/null 2>&1; then
    info "✅ Ollama engine is already installed ($(ollama --version 2>/dev/null | head -n 1 || echo unknown version))."
elif [[ $INSTALL_OLLAMA -eq 0 ]]; then
    die "Ollama is not installed and --no-ollama-install was given."
elif [[ $DRY_RUN -eq 1 ]]; then
    info "🧪 [dry-run] Would install Ollama via: curl -fsSL ${OLLAMA_INSTALL_URL} | sh"
else
    command -v curl >/dev/null 2>&1 || die "curl is required to install Ollama (sudo apt install curl)."
    info "📦 Installing Ollama engine (official installer, may ask for your sudo password)..."
    curl -fsSL "$OLLAMA_INSTALL_URL" | sh
    command -v ollama >/dev/null 2>&1 || die "Ollama installation finished but 'ollama' is not on PATH."
    info "✅ Ollama installed successfully!"
fi

# ------------------------------------------------------------------------------
# Disk space check
# ------------------------------------------------------------------------------
check_disk() {
    local need="$1" dir avail
    [[ -n "$need" ]] || return 0
    dir="${OLLAMA_MODELS:-}"
    if [[ -z "$dir" ]]; then
        if [[ -d /usr/share/ollama ]]; then dir="/usr/share/ollama"; else dir="$HOME/.ollama"; fi
    fi
    while [[ ! -d "$dir" && "$dir" != "/" ]]; do dir="$(dirname "$dir")"; done
    avail="$(df -Pk "$dir" 2>/dev/null | awk 'NR==2 {printf "%.1f", $4/1048576}')"
    [[ -n "$avail" ]] || return 0
    if awk -v a="$avail" -v n="$need" 'BEGIN {exit !(a < n * 1.15)}'; then
        warn "Only ${avail} GB free in ${dir}, but ${CHOSEN_MODEL} needs about ${need} GB."
        [[ $ASSUME_YES -eq 0 ]] || die "Not enough disk space (use --model with a smaller model)."
        confirm "Continue anyway?" || die "Aborted: not enough disk space."
    fi
}

# ------------------------------------------------------------------------------
# Download
# ------------------------------------------------------------------------------
if [[ $DRY_RUN -eq 1 ]]; then
    info "🧪 [dry-run] Would run: ollama pull ${CHOSEN_MODEL}"
    info "🧪 [dry-run] Nothing was changed."
    exit 0
fi

if ! confirm "⬇️  Download and activate ${CHOSEN_MODEL} now?"; then
    info "⏭️  Download skipped. Run 'ollama pull ${CHOSEN_MODEL}' whenever you're ready."
    exit 0
fi

check_disk "$CHOSEN_GB"
ensure_ollama_running

info "⏳ Pulling ${CHOSEN_MODEL} via Ollama..."
if ! ollama pull "$CHOSEN_MODEL"; then
    die "Pulling ${CHOSEN_MODEL} failed (typo in the tag, no network, or the model was removed). Run './install.sh --list' to see other options."
fi

echo ""
echo "🎉 Success! PromptOS is ready with ${CHOSEN_MODEL}."
echo "💡 Type 'ollama run ${CHOSEN_MODEL}' anytime to start chatting!"
