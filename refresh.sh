#!/usr/bin/env bash
set -euo pipefail

IMAGE_NAME="claude-auth"
CLAUDE_DIR="$HOME/.claude"
INTERACTIVE=false

usage() {
  cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Refresh Claude Code credentials via the container.

By default, performs a non-interactive refresh attempt. Use -i for an
interactive session if tokens are fully expired.

Options:
  -i, --interactive    Interactive re-authentication session
  -h, --help           Show this help message
EOF
}

for arg in "$@"; do
  case "$arg" in
    -i|--interactive) INTERACTIVE=true ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $arg"; usage; exit 1 ;;
  esac
done

if $INTERACTIVE; then
  echo "Starting interactive Claude session for re-authentication..."
  echo
  echo "  ┌─────────────────────────────────────────────────────────┐"
  echo "  │  1. If prompted, select your subscription plan (Pro/Max)│"
  echo "  │     NOT the API option                                 │"
  echo "  │  2. Once you see the Claude prompt, type /exit or      │"
  echo "  │     press Ctrl+D to quit                               │"
  echo "  └─────────────────────────────────────────────────────────┘"
  echo
  read -n 1 -s -r -p "  Press any key to continue..."
  echo
  echo
  docker run -it --rm \
    --name claude-auth-refresh \
    -v "$CLAUDE_DIR:/root/.claude" \
    "$IMAGE_NAME"
else
  echo "Refreshing Claude credentials (non-interactive)..."
  echo "  Note: this may not work if your tokens are fully expired."
  echo
  docker run --rm \
    --name claude-auth-refresh \
    -v "$CLAUDE_DIR:/root/.claude" \
    -e TERM=dumb \
    "$IMAGE_NAME" -p . --model haiku >/dev/null 2>&1 || true
fi

echo
if [ -f "$CLAUDE_DIR/.credentials.json" ]; then
  echo "Credentials refreshed at $CLAUDE_DIR/.credentials.json"
else
  echo "ERROR: Refresh failed. Try running with -i for interactive re-authentication." >&2
  exit 1
fi