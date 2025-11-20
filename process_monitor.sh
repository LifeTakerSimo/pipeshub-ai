#!/bin/bash

# Process monitor script with parent-child process management
set -e

LOG_FILE="/app/process_monitor.log"
CHECK_INTERVAL=10

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
}

start_query() {
    log "Starting Query service..."
    cd /app/python
    python -m app.query_main &
    QUERY_PID=$!
    log "Query started with PID: $QUERY_PID"
}

check_query_health() {
    # Verify the Query HTTP health endpoint responds
    # Give it up to 5 seconds to respond (service takes time to start)
    if curl -fsS --max-time 5 http://localhost:8000/health >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

restart_query() {
    log "Restarting Query service due to failed health check..."
    if [ -n "$QUERY_PID" ] && kill -0 "$QUERY_PID" 2>/dev/null; then
        # Check if service has been running for less than 60 seconds (still starting up)
        local pid_age=$(ps -o etime= -p "$QUERY_PID" 2>/dev/null | awk -F: '{if (NF==2) print $1*60+$2; else if (NF==3) print $1*3600+$2*60+$3; else print 0}')
        if [ -n "$pid_age" ] && [ "$pid_age" -lt 60 ]; then
            log "Query service still starting up (running for ${pid_age}s), skipping restart..."
            return 0
        fi
        kill "$QUERY_PID" 2>/dev/null || true
        # Give it a moment to terminate
        sleep 2
    fi
    start_query
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

# Start all services
log "=== Process Monitor Starting ==="
start_nodejs
start_connector
start_indexing
start_query
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
    else
        # Process exists; ensure HTTP health is good
        if ! check_query_health; then
            restart_query
        fi
    fi
done

