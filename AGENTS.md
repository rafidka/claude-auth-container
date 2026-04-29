# AGENTS.md

## Project Overview

Containerized Claude Code CLI setup for generating authentication credentials
used by the [opencode-claude-auth](https://github.com/griffinmartin/opencode-claude-auth)
plugin. Allows using the plugin without installing `claude` on the host machine.

## Commands

| Command | Description |
| ------- | ----------- |
| `./auth.sh` | Build image (if needed) and authenticate interactively |
| `./auth.sh --build` | Force rebuild the Docker image then authenticate |
| `./refresh.sh` | Non-interactive token refresh (haiku model) |
| `./refresh.sh -i` | Interactive re-authentication session |
| `docker build -t claude-auth .` | Build the Docker image directly |

## Architecture

- **Dockerfile** — Debian slim image with official Claude Code CLI installed via `curl`
- **auth.sh** — Initial authentication: builds image, runs interactive `claude` session,
  mounts `~/.claude` for credential persistence, detects stale macOS Keychain entries
- **refresh.sh** — Token refresh: non-interactive (`haiku`) or interactive (`--interactive`)
  fallback for when the plugin's direct OAuth refresh fails
- **.dockerignore** — Excludes scripts and docs from build context

## Key Details

- Credentials are stored at `~/.claude/.credentials.json` on the host, mounted into
  the container at `/root/.claude` via Docker volume
- The opencode-claude-auth plugin reads credentials in this order:
  1. macOS Keychain (`"Claude Code-credentials"` entries)
  2. `~/.claude/.credentials.json` (fallback — what this project produces)
- Stale Keychain entries from a previous native `claude` install will shadow the file
  and cause auth failures. `auth.sh` detects and offers to delete them.
- The plugin handles most token refreshes automatically via direct OAuth. The container
  is only needed as a fallback when direct refresh fails.
- Plugin debug logging: `CLAUDE_AUTH_DEBUG=1` → `~/.local/share/opencode/claude-auth-debug.log`

## Conventions

- Shell scripts use `set -euo pipefail` and `#!/usr/bin/env bash`
- No comments in code unless explicitly requested
- Docker image name: `claude-auth`