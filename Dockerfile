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
# Download NLTK and spaCy models
RUN python -m spacy download en_core_web_sm && \
    python -m nltk.downloader punkt && \
    python -c "from sentence_transformers import CrossEncoder; model = CrossEncoder(model_name='BAAI/bge-reranker-base')"

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

# Copy the process monitor script
COPY process_monitor.sh /app/process_monitor.sh
RUN chmod +x /app/process_monitor.sh

# Expose necessary ports
EXPOSE 3000 8000 8088 8091 8081

# Use the process monitor as the main process
CMD ["/app/process_monitor.sh"]
