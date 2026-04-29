FROM debian:bookworm-slim

LABEL org.opencontainers.image.title="claude-auth" \
      org.opencontainers.image.description="Containerized Claude Code CLI for credential management" \
      org.opencontainers.image.source="https://github.com/griffinmartin/opencode-claude-auth"

RUN apt-get update && \
    apt-get install -y --no-install-recommends curl ca-certificates && \
    rm -rf /var/lib/apt/lists/*

RUN curl -fsSL https://claude.ai/install.sh | bash

ENV PATH="/root/.local/bin:${PATH}"
ENTRYPOINT ["claude"]