#!/usr/bin/env bash
set -euo pipefail

# Robust model downloader with retries and exponential backoff.
# Downloads:
#  - spaCy en_core_web_sm
#  - NLTK punkt
#  - sentence_transformers CrossEncoder model
#
# Usage: ./scripts/download_models.sh  # runs default models
# Environment:
#  - RETRIES (default 5)
#  - SLEEP_BASE (default 5)

RETRIES=${RETRIES:-5}
SLEEP_BASE=${SLEEP_BASE:-5}

retry_cmd() {
  local attempt=1
  local max=$RETRIES
n  local sleep_base=$SLEEP_BASE
  local cmd="$@"

  while true; do
    echo "[download_models] attempt ${attempt}/${max}: $cmd"
    if bash -c "$cmd"; then
      echo "[download_models] success"
      return 0
    fi

    if [ "$attempt" -ge "$max" ]; then
      echo "[download_models] failed after $attempt attempts"
      return 1
    fi

    local sleep_time=$((sleep_base * attempt))
    echo "[download_models] command failed, sleeping ${sleep_time}s before retrying..."
    sleep $sleep_time
    attempt=$((attempt + 1))
  done
}

# 1) spaCy model
echo "[download_models] Downloading spaCy model en_core_web_sm"
retry_cmd "python -m spacy download en_core_web_sm"
spacy_exit=$?
if [ $spacy_exit -ne 0 ]; then
  echo "[download_models] WARNING: spaCy model download failed (non-fatal)."
fi

# 2) NLTK punkt
echo "[download_models] Downloading NLTK punkt"
retry_cmd "python -m nltk.downloader punkt"
nltk_exit=$?
if [ $nltk_exit -ne 0 ]; then
  echo "[download_models] WARNING: NLTK punkt download failed (non-fatal)."
fi

# 3) Sentence Transformers CrossEncoder (Hugging Face)
# This will download the model weights into the local cache. We attempt
# multiple retries because HF downloads can fail behind certain proxies.
echo "[download_models] Downloading CrossEncoder BAAI/bge-reranker-base"
retry_cmd "python -c \"from sentence_transformers import CrossEncoder; CrossEncoder(model_name='BAAI/bge-reranker-base')\""
ct_exit=$?
if [ $ct_exit -ne 0 ]; then
  echo "[download_models] WARNING: CrossEncoder download failed (non-fatal)."
fi

# Summarize
if [ $spacy_exit -eq 0 ] || [ $nltk_exit -eq 0 ] || [ $ct_exit -eq 0 ]; then
  echo "[download_models] Finished (some successes or partial)."
else
  echo "[download_models] All downloads failed. You can re-run the script or run it with better network access."
fi

exit 0
