FROM ubuntu:22.04

# Environment variables
ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

WORKDIR /workspace

# Install git if not present (most base images have it, but just in case)
RUN apt-get update && apt-get install -y git && rm -rf /var/lib/apt/lists/*

# Clone repository
RUN git clone https://github.com/simonw/llm-claude-3.git /workspace/repo && cd /workspace/repo && git checkout c62bf247fa964ff350badf5424743ddca7601d4a

WORKDIR /workspace/repo

# Create script to copy repository content to workspace
RUN echo '#!/bin/bash' > /usr/local/bin/copy-repo.sh && \
    echo 'echo "Copying repository content to workspace..."' >> /usr/local/bin/copy-repo.sh && \
    echo 'if [ -d "/workspace/repo" ] && [ -d "/workspaces" ]; then' >> /usr/local/bin/copy-repo.sh && \
    echo '  # Find the workspace directory' >> /usr/local/bin/copy-repo.sh && \
    echo '  WORKSPACE_DIR=$(find /workspaces -maxdepth 1 -type d ! -path /workspaces | head -1)' >> /usr/local/bin/copy-repo.sh && \
    echo '  if [ -n "$WORKSPACE_DIR" ] && [ -d "$WORKSPACE_DIR" ]; then' >> /usr/local/bin/copy-repo.sh && \
    echo '    echo "Found workspace directory: $WORKSPACE_DIR"' >> /usr/local/bin/copy-repo.sh && \
    echo '    # Copy repository files to workspace directory' >> /usr/local/bin/copy-repo.sh && \
    echo '    cp -r /workspace/repo/. "$WORKSPACE_DIR/" 2>/dev/null || true' >> /usr/local/bin/copy-repo.sh && \
    echo '    echo "Repository files copied to workspace"' >> /usr/local/bin/copy-repo.sh && \
    echo '  else' >> /usr/local/bin/copy-repo.sh && \
    echo '    echo "No workspace directory found"' >> /usr/local/bin/copy-repo.sh && \
    echo '  fi' >> /usr/local/bin/copy-repo.sh && \
    echo 'else' >> /usr/local/bin/copy-repo.sh && \
    echo '  echo "Source or target directory not found"' >> /usr/local/bin/copy-repo.sh && \
    echo 'fi' >> /usr/local/bin/copy-repo.sh && \
    chmod +x /usr/local/bin/copy-repo.sh

# Setup script
RUN echo '#!/bin/bash' > /tmp/setup.sh && \
    echo 'set -e' >> /tmp/setup.sh && \
    echo "# Install system dependencies" >> /tmp/setup.sh && \
    echo "apt-get update && apt-get install -y python3 python3-pip python3-venv python3-dev git curl wget build-essential libssl-dev libffi-dev pkg-config ca-certificates" >> /tmp/setup.sh && \
    echo "rm -rf /var/lib/apt/lists/*" >> /tmp/setup.sh && \
    echo "# Set up Python 3 as default python" >> /tmp/setup.sh && \
    echo "update-alternatives --install /usr/bin/python python /usr/bin/python3 1" >> /tmp/setup.sh && \
    echo "update-alternatives --install /usr/bin/pip pip /usr/bin/pip3 1" >> /tmp/setup.sh && \
    echo "# Install the project dependencies" >> /tmp/setup.sh && \
    echo "pip install ." >> /tmp/setup.sh && \
    echo "# Install additional useful tools for development" >> /tmp/setup.sh && \
    echo "pip install pytest pytest-recording black ruff mypy" >> /tmp/setup.sh && \
    chmod +x /tmp/setup.sh && \
    /tmp/setup.sh

# Create user developer
RUN useradd -m -s /bin/bash developer
USER developer

EXPOSE 8000
EXPOSE 8080
EXPOSE 3000