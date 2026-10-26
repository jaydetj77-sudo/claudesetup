#!/bin/bash
# ------------------------------------------------------------
#  Workshop setup for Mac
#  Installs: Python 3.14, Node.js, Git, GitHub CLI,
#            Supabase CLI, Vercel CLI and Claude Code.
#  Safe to run more than once - it skips anything already there.
#
#  How to run:        bash setup-mac.sh
#  Check only:        bash setup-mac.sh --check-only
#                     (shows what's missing, installs nothing)
# ------------------------------------------------------------

set -u

# ---------- Settings you can change ----------
MIN_PYTHON="3.14"
BREW_PYTHON="python@3.14"
MIN_NODE=18
# ---------------------------------------------

CHECK_ONLY=0
for arg in "$@"; do
  case "$arg" in
    --check-only|--diagnose-only) CHECK_ONLY=1 ;;
    -h|--help)
      echo "Usage: bash setup-mac.sh [--check-only]"
      echo "  --check-only   Show what's installed or missing. Installs nothing."
      exit 0 ;;
  esac
done

GREEN=$'\033[0;32m'; YELLOW=$'\033[1;33m'; RED=$'\033[0;31m'
BLUE=$'\033[0;34m'; GREY=$'\033[0;90m'; BOLD=$'\033[1m'; RESET=$'\033[0m'

say()  { echo; echo "${BLUE}==>${RESET} ${BOLD}$*${RESET}"; }
ok()   { echo "    ${GREEN}✓${RESET} $*"; }
warn() { echo "    ${YELLOW}!${RESET} $*"; }
bad()  { echo "    ${RED}✗${RESET} $*"; }

START_TIME=$(date +%s)
STAMP=$(date +%Y%m%d-%H%M%S)
LOG_FILE="$HOME/workshop-setup-$STAMP.log"
# Show everything on screen and save a copy (without colors) to the log file
exec > >(tee >(sed -E $'s/\033\\[[0-9;]*m//g' >> "$LOG_FILE")) 2>&1

RESULTS=()
record() { RESULTS+=("$1|$2|${3:-}"); }   # name|status|note
has()    { command -v "$1" >/dev/null 2>&1; }

case "$(basename "${SHELL:-zsh}")" in
  zsh)  PROFILE="$HOME/.zshrc" ;;
  bash) PROFILE="$HOME/.bash_profile" ;;
  *)    PROFILE="$HOME/.profile" ;;
esac

add_to_profile() {
  [ "$CHECK_ONLY" -eq 1 ] && return 0
  touch "$PROFILE"
  grep -qxF "$1" "$PROFILE" 2>/dev/null || echo "$1" >> "$PROFILE"
}

# Returns success if version $1 >= version $2
version_ok() {
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<< "$1"; IFS=. read -r b1 b2 b3 <<< "$2"
  for pair in "${a1:-0} ${b1:-0}" "${a2:-0} ${b2:-0}" "${a3:-0} ${b3:-0}"; do
    set -- $pair
    [ "$1" -gt "$2" ] && return 0
    [ "$1" -lt "$2" ] && return 1
  done
  return 0
}

echo
echo "${BOLD}=============================================${RESET}"
echo "${BOLD}   Vibe Coding Workshop - Mac setup${RESET}"
echo "${BOLD}=============================================${RESET}"
if [ "$CHECK_ONLY" -eq 1 ]; then
  echo "${YELLOW}CHECK-ONLY MODE: nothing will be installed or changed.${RESET}"
else
  echo "This takes 5-20 minutes. It may look stuck at times - that's normal."
  echo "If it asks for your Mac password, type it (letters won't show) and press Enter."
fi

if [ "$(uname)" != "Darwin" ]; then
  bad "This script is for Mac only."
  exit 1
fi

# ---------- Back up shell settings ----------
BACKUP_DIR="$HOME/dotfile-backups"
if [ "$CHECK_ONLY" -eq 0 ]; then
  mkdir -p "$BACKUP_DIR"
  for f in .zshrc .bash_profile .profile .bashrc; do
    [ -f "$HOME/$f" ] && cp "$HOME/$f" "$BACKUP_DIR/$f.$STAMP"
  done
fi

# ---------- 1. Apple Command Line Tools ----------
say "Apple Command Line Tools"
if xcode-select -p >/dev/null 2>&1; then
  ok "Already installed"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  bad "Missing (would ask to install)"
else
  warn "Not found. A pop-up box will appear - click Install."
  xcode-select --install >/dev/null 2>&1 || true
  echo
  echo "${YELLOW}${BOLD}When that install finishes, run this script again.${RESET}"
  exit 0
fi

# ---------- 2. Homebrew ----------
say "Homebrew (installer for developer tools)"
if ! has brew; then
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [ -x "$p" ] && eval "$("$p" shellenv)" && break
  done
fi
if has brew; then
  ok "Already installed"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  bad "Missing (would install)"
else
  warn "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  for p in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    if [ -x "$p" ]; then
      eval "$("$p" shellenv)"
      add_to_profile "eval \"\$($p shellenv)\""
      break
    fi
  done
  if has brew; then ok "Homebrew installed"; else bad "Homebrew install failed"; fi
fi
if ! has brew && [ "$CHECK_ONLY" -eq 0 ]; then
  echo
  echo "${RED}${BOLD}Homebrew is needed for everything else.${RESET}"
  echo "Close Terminal, open a new one, and run this script again."
  echo "Log saved to: $LOG_FILE"
  exit 1
fi

# install_tool <name> <command> <install command...>
install_tool() {
  local name="$1" cmd="$2"; shift 2
  say "$name"
  if has "$cmd"; then
    ok "Already installed"
    record "$name" "AlreadyInstalled"
  elif [ "$CHECK_ONLY" -eq 1 ]; then
    bad "Missing (would install)"
    record "$name" "Missing"
  else
    warn "Installing..."
    if "$@" && has "$cmd"; then
      ok "Installed"
      record "$name" "Installed"
    else
      bad "Could not install"
      record "$name" "Failed"
    fi
  fi
}

# ---------- 3. Python ----------
say "Python (need $MIN_PYTHON or newer)"
PY_VER=""; OLD_PY=""
for py in python3.14 python3; do
  if has "$py"; then
    v=$("$py" -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null)
    if [ -n "$v" ] && version_ok "$v" "$MIN_PYTHON"; then PY_VER="$v"; break; fi
    [ -z "$PY_VER" ] && OLD_PY="$v"
  fi
done
if [ -n "$PY_VER" ]; then
  ok "Python $PY_VER already installed"
  record "Python" "AlreadyInstalled"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  bad "Missing or too old${OLD_PY:+ (found $OLD_PY)}"
  record "Python" "Missing" "need $MIN_PYTHON+"
else
  [ -n "${OLD_PY:-}" ] && warn "Found Python $OLD_PY, which is too old"
  warn "Installing Python $MIN_PYTHON..."
  if brew install "$BREW_PYTHON"; then
    PY_BIN="$(brew --prefix "$BREW_PYTHON")/libexec/bin"
    export PATH="$PY_BIN:$PATH"
    add_to_profile "export PATH=\"$PY_BIN:\$PATH\""
    hash -r
    NEW_PY=$(python3 -c 'import sys; print(".".join(map(str, sys.version_info[:3])))' 2>/dev/null)
    if [ -n "$NEW_PY" ] && version_ok "$NEW_PY" "$MIN_PYTHON"; then
      ok "Installed"
      record "Python" "Installed"
    else
      bad "Installed, but your Mac is still using an older Python (${NEW_PY:-none})"
      record "Python" "Failed" "open a new Terminal and run again"
    fi
  else
    bad "Could not install"
    record "Python" "Failed"
  fi
fi

# ---------- 4. Node.js ----------
say "Node.js (need v$MIN_NODE or newer)"
NODE_MAJOR=0
has node && NODE_MAJOR=$(node -v 2>/dev/null | sed 's/^v//' | cut -d. -f1)
if [ "${NODE_MAJOR:-0}" -ge "$MIN_NODE" ] 2>/dev/null; then
  ok "Node.js $(node -v) already installed"
  record "Node.js" "AlreadyInstalled"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  bad "Missing or too old"
  record "Node.js" "Missing" "need v$MIN_NODE+"
else
  [ "${NODE_MAJOR:-0}" -gt 0 ] && warn "Found Node.js v$NODE_MAJOR, which is too old"
  warn "Installing..."
  if brew install node && has node; then
    ok "Installed"
    record "Node.js" "Installed"
  else
    bad "Could not install"
    record "Node.js" "Failed"
  fi
fi

# ---------- 5-7. Git, GitHub CLI, Supabase CLI ----------
install_tool "Git"          git      brew install git
install_tool "GitHub CLI"   gh       brew install gh
install_tool "Supabase CLI" supabase brew install supabase/tap/supabase

# ---------- 8. Vercel CLI ----------
if has npm || [ "$CHECK_ONLY" -eq 1 ]; then
  install_tool "Vercel CLI" vercel npm install -g vercel
else
  say "Vercel CLI"
  bad "Needs Node.js, which isn't working"
  record "Vercel CLI" "Failed" "Node.js missing"
fi

# ---------- 9. Claude Code ----------
say "Claude Code"
export PATH="$HOME/.local/bin:$PATH"
if has claude; then
  ok "Already installed"
  record "Claude Code" "AlreadyInstalled"
elif [ "$CHECK_ONLY" -eq 1 ]; then
  bad "Missing (would install)"
  record "Claude Code" "Missing"
else
  warn "Installing..."
  curl -fsSL https://claude.ai/install.sh | bash
  if ! has claude && has npm; then
    warn "Trying the backup install method..."
    npm install -g @anthropic-ai/claude-code
  fi
  add_to_profile 'export PATH="$HOME/.local/bin:$PATH"'
  if has claude; then
    ok "Installed"
    record "Claude Code" "Installed"
  else
    bad "Could not install"
    record "Claude Code" "Failed"
  fi
fi

# ---------- Git name and email (just a reminder) ----------
GIT_NAME_SET=0
if has git && [ -n "$(git config --global user.name 2>/dev/null)" ] && [ -n "$(git config --global user.email 2>/dev/null)" ]; then
  GIT_NAME_SET=1
fi

# ---------- Results table ----------
tool_cmd() {
  case "$1" in
    "Python") echo python3 ;; "Node.js") echo node ;; "Git") echo git ;;
    "GitHub CLI") echo gh ;; "Supabase CLI") echo supabase ;;
    "Vercel CLI") echo vercel ;; "Claude Code") echo claude ;;
  esac
}
get_version() {
  local c; c=$(tool_cmd "$1")
  has "$c" || return 0
  "$c" --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n1
}

echo
echo "${BOLD}=============================================${RESET}"
echo "${BOLD}   RESULTS${RESET}"
echo "${BOLD}=============================================${RESET}"
printf "  ${BOLD}%-14s %-18s %-10s %s${RESET}\n" "Tool" "Status" "Version" "Location"
printf "  %-14s %-18s %-10s %s\n" "--------------" "----------------" "--------" "--------"
FAILED=0; MISSING=0
for row in "${RESULTS[@]}"; do
  IFS='|' read -r name status note <<< "$row"
  ver="$(get_version "$name")"
  loc="$(command -v "$(tool_cmd "$name")" 2>/dev/null)"
  case "$status" in
    Installed|AlreadyInstalled) color=$GREEN ;;
    Missing) color=$YELLOW; MISSING=$((MISSING + 1)) ;;
    *)       color=$RED;    FAILED=$((FAILED + 1)) ;;
  esac
  printf "  %-14s ${color}%-18s${RESET} %-10s ${GREY}%s${RESET}\n" "$name" "$status" "${ver:--}" "${loc:-${note:--}}"
done

ELAPSED=$(( $(date +%s) - START_TIME ))
echo
if [ "$CHECK_ONLY" -eq 1 ]; then
  if [ "$MISSING" -eq 0 ]; then
    echo "${GREEN}${BOLD}Everything is already installed.${RESET}"
  else
    echo "${YELLOW}${BOLD}$MISSING tool(s) missing.${RESET} Run without --check-only to install them:"
    echo "  bash setup-mac.sh"
  fi
elif [ "$FAILED" -eq 0 ]; then
  echo "${GREEN}${BOLD}=============================================${RESET}"
  echo "${GREEN}${BOLD}   ALL GREEN - setup complete!${RESET}"
  echo "${GREEN}${BOLD}=============================================${RESET}"
  echo
  echo "${BOLD}Last step - sign in to your tools:${RESET}"
  echo "  1. Quit Terminal (Cmd + Q) and open a new one."
  echo "  2. Run these one at a time, waiting for each to finish:"
  echo
  echo "     gh auth login"
  echo "     supabase login"
  echo "     vercel login"
  echo "     git config --global user.name \"Your Name\""
  echo "     git config --global user.email \"your@email.com\""
  [ "$GIT_NAME_SET" -eq 1 ] && echo "${GREY}     (Your git name and email are already set - you can skip the last two.)${RESET}"
else
  echo "${RED}${BOLD}=============================================${RESET}"
  echo "${RED}${BOLD}   $FAILED tool(s) FAILED${RESET}"
  echo "${RED}${BOLD}=============================================${RESET}"
  echo
  echo "Fix: quit Terminal (Cmd + Q), open a new one, and run this script again."
  echo "It's safe to run as many times as needed."
  echo "Still failing? Send a screenshot of this table to a workshop assistant."
fi
echo
echo "${GREY}Finished in $((ELAPSED / 60)) min $((ELAPSED % 60)) sec.${RESET}"
echo "${GREY}Log saved to: $LOG_FILE${RESET}"
[ "$CHECK_ONLY" -eq 0 ] && echo "${GREY}Old shell settings backed up to: $BACKUP_DIR${RESET}"
echo
