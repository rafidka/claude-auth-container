#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-auth"
CLAUDE_DIR="$HOME/.claude"
OPENCODE_CONFIG="$HOME/.config/opencode/opencode.json"
FORCE_BUILD=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Authenticate with Claude Code inside a container and extract credentials
for use with the opencode-claude-auth plugin.

Options:
  --build    Force rebuild the Docker image even if it already exists
  -h, --help Show this help message
EOF
}

for arg in "$@"; do
  case "$arg" in
    --build) FORCE_BUILD=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

echo "=== Claude Auth Container Setup ==="
echo

# --- Step 1: Build or reuse the Docker image ---
if $FORCE_BUILD || ! docker image inspect "$IMAGE_NAME" &>/dev/null; then
  echo "[1/3] Building Docker image..."
  docker build -t "$IMAGE_NAME" "$(dirname "$0")"
else
  echo "[1/3] Docker image '$IMAGE_NAME' already exists (use --build to rebuild)"
fi
echo

# --- Step 2: Check for stale macOS Keychain entries ---
echo "[2/3] Pre-flight checks..."
if [[ "$(uname -s)" == "Darwin" ]]; then
  if security find-generic-password -s "Claude Code-credentials" ~/Library/Keychains/login.keychain-db &>/dev/null; then
    echo
    echo "  WARNING: A 'Claude Code-credentials' entry exists in your macOS Keychain."
    echo "  The plugin reads Keychain entries first and will use stale credentials"
    echo "  instead of the file-based ones from this container."
    echo
    read -rp "  Delete the Keychain entry? [Y/n] " reply
    if [[ -z "$reply" || "${reply,,}" == "y" ]]; then
      security delete-generic-password -s "Claude Code-credentials" ~/Library/Keychains/login.keychain-db
      echo "  Deleted."
    else
      echo "  Skipped. If auth fails, run:"
      echo "    security delete-generic-password -s 'Claude Code-credentials' ~/Library/Keychains/login.keychain-db"
    fi
    echo
  fi
fi

mkdir -p "$CLAUDE_DIR"

echo "Starting interactive Claude session..."
echo
echo "  ┌─────────────────────────────────────────────────────────┐"
echo "  │  1. Log in with your Anthropic account                 │"
echo "  │  2. Once you see the Claude prompt, type /exit or      │"
echo "  │     press Ctrl+D to quit                               │"
echo "  └─────────────────────────────────────────────────────────┘"
echo
read -n 1 -s -r -p "  Press any key to continue..."
echo
echo

docker run -it --rm \
  --name claude-auth-session \
  -v "$CLAUDE_DIR:/root/.claude" \
  "$IMAGE_NAME"

# --- Step 3: Verify credentials ---
echo
echo "[3/3] Verifying credentials..."
if [ -f "$CLAUDE_DIR/.credentials.json" ]; then
  echo "  Credentials found at $CLAUDE_DIR/.credentials.json"
else
  echo "  ERROR: No credentials file found. Try running this script again." >&2
  exit 1
fi

# --- Post-setup instructions ---
echo
echo "=== Done! ==="
echo

if [ -f "$OPENCODE_CONFIG" ] && grep -q "opencode-claude-auth" "$OPENCODE_CONFIG" 2>/dev/null; then
  echo "The opencode-claude-auth plugin is already configured."
else
  echo "Add the plugin to your opencode.json:"
  echo
  echo '  { "plugin": ["opencode-claude-auth@latest"] }'
  echo
  echo "  at $OPENCODE_CONFIG"
fi

echo
echo "To refresh credentials later, run: ./refresh.sh"