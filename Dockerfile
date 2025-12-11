# Stage 1: Base dependencies
FROM python:3.10-slim AS base
ENV DEBIAN_FRONTEND=noninteractive TZ=Etc/UTC

WORKDIR /app

RUN pip install uv

# Install system dependencies and necessary runtime libraries
RUN apt-get update && apt-get install -y \
    curl build-essential gnupg iputils-ping telnet traceroute dnsutils net-tools wget \
    librocksdb-dev libgflags-dev libsnappy-dev zlib1g-dev \
    libbz2-dev liblz4-dev libzstd-dev libssl-dev ca-certificates libspatialindex-dev libpq5 && \
    curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get install -y nodejs && \
    apt-get install -y libreoffice && \
    apt-get install -y ocrmypdf tesseract-ocr ghostscript unpaper qpdf && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

RUN curl https://sh.rustup.rs -sSf | sh -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"

# Stage 2: Python dependencies
FROM base AS python-deps
COPY ./backend/python/pyproject.toml /app/python/
WORKDIR /app/python
# Increase HTTP timeout for the `uv` wrapper and pip to reduce failures when
# downloading large binary wheels (CUDA toolkits etc). Also pre-install the
# CPU-only PyTorch wheel so pip won't try to download CUDA-enabled wheels
# which often fail in CI/container environments without GPUs.
ENV UV_HTTP_TIMEOUT=300
ENV PIP_DEFAULT_TIMEOUT=100

# Pre-install CPU-only torch from the official PyTorch CPU wheel index. This
# ensures that installing the project (which depends on `torch`) will pick the
# CPU wheel instead of attempting to download CUDA variants like
# `nvidia-cublas-cu12`.
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu/ "torch==2.9.1+cpu" || true

RUN uv pip install --system -e .
# NOTE: downloading large NLP/model artifacts during the Docker build is
# fragile (network timeouts, GitHub/HuggingFace rate limits) and often causes
# build failures (504/timeout). We remove the direct download from the build
# to make the image build deterministic and fast.
#
# If you need the models, run the included script at runtime (it implements
# retries and backoff): `/app/scripts/download_models.sh`.
# You can enable automatic download on container startup by setting the
# environment variable `RUN_MODEL_DOWNLOAD_ON_STARTUP=true` (see runtime
# `process_monitor.sh` which will conditionally run the script).

## The model download step was intentionally removed from the build to avoid
## 504/timeouts. See scripts/download_models.sh for a robust downloader that
## can be executed post-build (or in CI with proper network access).

# Stage 3: Node.js backend
FROM base AS nodejs-backend
WORKDIR /app/backend

COPY backend/nodejs/apps/package*.json ./
COPY backend/nodejs/apps/tsconfig.json ./

# Set up architecture detection and conditional handling
RUN set -e; \
    # Detect architecture
    ARCH=$(uname -m); \
    echo "Building for architecture: $ARCH"; \
    # Platform-specific handling
    if [ "$ARCH" = "arm64" ] || [ "$ARCH" = "aarch64" ]; then \
        echo "Detected ARM architecture (M1/Apple Silicon)"; \
        # ARM-specific handling: Skip problematic binary or use alternative
        npm install --prefix ./ --ignore-scripts && \
	npm uninstall jpeg-recompress-bin mozjpeg imagemin-mozjpeg 2>/dev/null || true; \
        # Install Sharp AS a better alternative for ARM64
        npm install sharp --save || echo "Sharp install failed, continuing without image optimization"; \
    else \
        echo "Detected x86 architecture"; \
        # Standard install for x86 platforms
        apt-get update && apt-get install -y libc6-dev-i386 && npm install --prefix ./; \
    fi

COPY backend/nodejs/apps/src ./src
RUN npm run build

# Stage 4: Frontend build
FROM base AS frontend-build
WORKDIR /app/frontend
RUN mkdir -p packages
COPY frontend/package*.json ./
COPY frontend/packages ./packages/
RUN npm config set legacy-peer-deps true && npm install
COPY frontend/ ./
RUN npm run build

# Stage 5: Final runtime
FROM python-deps AS runtime
WORKDIR /app

COPY --from=nodejs-backend /app/backend/dist ./backend/dist
COPY --from=nodejs-backend /app/backend/src/modules/mail ./backend/src/modules/mail
COPY --from=nodejs-backend /app/backend/src/modules/storage/docs/swagger.yaml ./backend/src/modules/storage/docs/swagger.yaml
COPY --from=nodejs-backend /app/backend/node_modules ./backend/dist/node_modules
COPY --from=frontend-build /app/frontend/dist ./backend/dist/public
COPY backend/python/app/ /app/python/app/

# Copy model downloader script into the final image. This script is NOT run
# during build by default. To run it automatically at container startup set
# RUN_MODEL_DOWNLOAD_ON_STARTUP=true in your docker-compose or container env.
COPY scripts/download_models.sh /app/scripts/download_models.sh
RUN chmod +x /app/scripts/download_models.sh || true

# Copy the process monitor script
COPY <<'EOF' /app/process_monitor.sh
#!/bin/bash

# Process monitor script with parent-child process management
set -e

# Optional: download large NLP models at container startup if requested.
# Set RUN_MODEL_DOWNLOAD_ON_STARTUP=true to run `/app/scripts/download_models.sh`
# before starting services. This makes builds reliable while still allowing
# automated model provisioning at runtime when network access is available.
if [ "${RUN_MODEL_DOWNLOAD_ON_STARTUP:-false}" = "true" ]; then
    echo "[process_monitor] RUN_MODEL_DOWNLOAD_ON_STARTUP=true -> starting model download"
    /app/scripts/download_models.sh || echo "[process_monitor] model download script failed (non-fatal)"
fi

LOG_FILE="/app/process_monitor.log"
CHECK_INTERVAL=${CHECK_INTERVAL:-20}

# PIDs of child processes
NODEJS_PID=""
DOCLING_PID=""
INDEXING_PID=""
CONNECTOR_PID=""
QUERY_PID=""

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$LOG_FILE"
}

start_nodejs() {
    log "Starting Node.js service..."
    cd /app/backend
    node dist/index.js &
    NODEJS_PID=$!
    log "Node.js started with PID: $NODEJS_PID"
    
    # Wait for Node.js health check to pass
    log "Waiting for Node.js health check..."
    local MAX_RETRIES=30
    local RETRY_COUNT=0
    local HEALTH_CHECK_URL="http://localhost:3000/api/v1/health"
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s -f "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            log "Node.js health check passed!"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        log "Health check attempt $RETRY_COUNT/$MAX_RETRIES failed, retrying in 2 seconds..."
        sleep 2
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log "ERROR: Node.js health check failed after $MAX_RETRIES attempts"
        return 1
    fi
}

start_docling() {
    log "Starting Docling service..."
    cd /app/python
    python -m app.docling_main &
    DOCLING_PID=$!
    log "Docling started with PID: $DOCLING_PID"
}

start_indexing() {
    log "Starting Indexing service..."
    cd /app/python
    python -m app.indexing_main &
    INDEXING_PID=$!
    log "Indexing started with PID: $INDEXING_PID"
}

start_connector() {
    log "Starting Connector service..."
    cd /app/python
    python -m app.connectors_main &
    CONNECTOR_PID=$!
    log "Connector started with PID: $CONNECTOR_PID"
    
    # Wait for Connector health check to pass
    log "Waiting for Connector health check..."
    local MAX_RETRIES=30
    local RETRY_COUNT=0
    local HEALTH_CHECK_URL="http://localhost:8088/health"
    
    while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
        if curl -s -f "$HEALTH_CHECK_URL" > /dev/null 2>&1; then
            log "Connector health check passed!"
            break
        fi
        RETRY_COUNT=$((RETRY_COUNT + 1))
        log "Health check attempt $RETRY_COUNT/$MAX_RETRIES failed, retrying in 2 seconds..."
        sleep 2
    done
    
    if [ $RETRY_COUNT -eq $MAX_RETRIES ]; then
        log "ERROR: Connector health check failed after $MAX_RETRIES attempts"
        return 1
    fi
}

start_query() {
    log "Starting Query service..."
    cd /app/python
    python -m app.query_main &
    QUERY_PID=$!
    log "Query started with PID: $QUERY_PID"
}

check_process() {
    local pid=$1
    local name=$2
    
    if [ -z "$pid" ] || ! kill -0 "$pid" 2>/dev/null; then
        log "WARNING: $name (PID: $pid) is not running!"
        return 1
    fi
    return 0
}

cleanup() {
    log "Shutting down all services..."
    
    [ -n "$NODEJS_PID" ] && kill "$NODEJS_PID" 2>/dev/null || true
    [ -n "$DOCLING_PID" ] && kill "$DOCLING_PID" 2>/dev/null || true
    [ -n "$INDEXING_PID" ] && kill "$INDEXING_PID" 2>/dev/null || true
    [ -n "$CONNECTOR_PID" ] && kill "$CONNECTOR_PID" 2>/dev/null || true
    [ -n "$QUERY_PID" ] && kill "$QUERY_PID" 2>/dev/null || true
    
    wait
    log "All services stopped."
    exit 0
}

# Trap signals for graceful shutdown
trap cleanup SIGTERM SIGINT SIGQUIT

# Start all services in dependency order
log "=== Process Monitor Starting ==="
# 1. Start Node.js first and wait for health check
start_nodejs
# 2. Start Connector after Node.js is healthy, wait for health check
start_connector
# 3. Start Indexing and Query after Connector is healthy (order doesn't matter)
start_indexing
start_query
# 4. Start Docling (can run independently)
start_docling

log "All services started. Beginning monitoring cycle (checking every ${CHECK_INTERVAL}s)..."

# Monitor loop
while true; do
    sleep "$CHECK_INTERVAL"
    
    # Check and restart Node.js
    if ! check_process "$NODEJS_PID" "Node.js"; then
        start_nodejs
    fi
    
    # Check and restart Docling
    if ! check_process "$DOCLING_PID" "Docling"; then
        start_docling
    fi
    
    # Check and restart Indexing
    if ! check_process "$INDEXING_PID" "Indexing"; then
        start_indexing
    fi
    
    # Check and restart Connector
    if ! check_process "$CONNECTOR_PID" "Connector"; then
        start_connector
    fi
    
    # Check and restart Query
    if ! check_process "$QUERY_PID" "Query"; then
        start_query
    fi
done
EOF

RUN chmod +x /app/process_monitor.sh

# Expose necessary ports
EXPOSE 3000 8000 8088 8091 8081

# Use the process monitor as the main process
CMD ["/app/process_monitor.sh"]
