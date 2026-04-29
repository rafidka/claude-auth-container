# claude-auth-container

Run [Claude Code](https://code.claude.com) inside a Docker container to generate
authentication credentials for the
[opencode-claude-auth](https://github.com/griffinmartin/opencode-claude-auth)
plugin — without installing `claude` on your host machine.

## Prerequisites

- [Docker](https://docs.docker.com/get-docker/)
- [OpenCode](https://opencode.ai)

## Quick Start

```bash
# 1. Build the image and authenticate
./auth.sh
```

The script will show instructions, then drop you into an interactive Claude
Code session inside the container. **Log in with your Anthropic account and
choose a subscription plan (Pro/Max) — do NOT choose the API option, as this
plugin relies on subscription credentials.** Then type `/exit` or press
`Ctrl+D` to quit. Credentials are saved to your host automatically.

```bash
# 2. Add the plugin to OpenCode (if not already configured)
#    Edit ~/.config/opencode/opencode.json:
#    { "plugin": ["opencode-claude-auth@latest"] }

# 3. Restart OpenCode — the plugin picks up credentials automatically
```

## Scripts

### `auth.sh` — Initial Authentication

Builds the Docker image (skips if it already exists) and starts an interactive
Claude Code session. Credentials are written to `~/.claude/.credentials.json`
on your host via a volume mount.

| Flag        | Description                                    |
| ----------- | ---------------------------------------------- |
| `--build`   | Force rebuild the Docker image                |
| `-h`        | Show help                                      |

On **macOS**, `auth.sh` also checks for stale `"Claude Code-credentials"`
Keychain entries and offers to delete them. The plugin reads Keychain entries
first — if a stale entry exists, it will be used instead of the file, causing
authentication failures.

### `refresh.sh` — Token Refresh

Re-authenticates with Claude Code to refresh credentials. The
opencode-claude-auth plugin handles most token renewals automatically via
direct OAuth refresh — this script is only needed as a fallback.

Runs an interactive session by default. Use `--quick` for a non-interactive
attempt (unreliable if tokens are fully expired).

| Flag            | Description                                         |
| --------------- | --------------------------------------------------- |
| `-q`, `--quick` | Non-interactive refresh attempt (may not work) |
| `-h`            | Show help                                           |

```bash
# Interactive re-authentication (default, recommended)
./refresh.sh

# Non-interactive attempt (use only if tokens are still partially valid)
./refresh.sh --quick
```

## How It Works

1. The Docker image installs the Claude Code CLI using the official installer
2. `auth.sh` mounts `~/.claude` into the container and runs `claude` interactively
3. You authenticate inside the container — credentials persist on your host
4. The opencode-claude-auth plugin reads `~/.claude/.credentials.json` as its
   credential source (falls back from macOS Keychain)
5. Token refresh is handled automatically by the plugin via direct OAuth —
   the container is only needed if direct refresh fails

## Troubleshooting

### "Credentials not found" in OpenCode

Make sure `~/.claude/.credentials.json` exists and contains `accessToken` and
`refreshToken` fields. Re-run `./auth.sh` to regenerate.

### Stale macOS Keychain entries

If you previously had `claude` installed natively on macOS, a stale
`"Claude Code-credentials"` Keychain entry may take priority over the file.
Delete it:

```bash
security delete-generic-password -s "Claude Code-credentials" ~/Library/Keychains/login.keychain-db
```

`auth.sh` checks for this automatically and offers to clean it up.

### Token refresh failures

The plugin refreshes tokens automatically via direct OAuth. If that fails
(e.g. Anthropic changes their endpoint), run:

```bash
./refresh.sh --interactive
```

### Debug logging

Enable the plugin's diagnostic logging to troubleshoot auth issues:

```bash
export CLAUDE_AUTH_DEBUG=1
# Logs written to ~/.local/share/opencode/claude-auth-debug.log
```

To disable:

```bash
unset CLAUDE_AUTH_DEBUG
```