FROM swe-arena-base

# Pin repository snapshot for reproducible builds.
ENV COMMIT_HASH=02b6580f16c7dc01199aa376a8018f7bd6ce4e67
ENV REPO_URL=https://github.com/Env2202/pyan.git
ENV REPO_NAME=pyan

WORKDIR /testbed/${REPO_NAME}

# Fetch exactly one commit, matching the provided base pattern.
RUN git init && \
  git remote add origin ${REPO_URL} && \
  git fetch --depth 1 origin ${COMMIT_HASH} && \
  git checkout FETCH_HEAD && \
  git remote remove origin

# Install OS packages needed by pyan:
# - python3/pip/venv: runtime + virtualenv support
# - graphviz: needed for SVG/HTML outputs (dot command)
# - git: retained for tooling workflows
RUN apt-get update && \
  apt-get install -y --no-install-recommends \
    python3 \
    python3-pip \
    python3-venv \
    graphviz \
    git && \
  rm -rf /var/lib/apt/lists/*

# Install uv (project-recommended workflow) and sync test/dev deps.
RUN python3 -m pip install --no-cache-dir --upgrade pip && \
  python3 -m pip install --no-cache-dir uv && \
  uv sync --extra test --extra dev

# Default command prints CLI help; override in `docker run` as needed.
CMD ["uv", "run", "pyan3", "--help"]
