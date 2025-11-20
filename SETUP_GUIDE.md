# PipesHub AI - Setup and Launch Guide

This guide will help you set up and launch the PipesHub AI project without encountering common issues.

## 📋 Prerequisites

1. **Docker Desktop** - Must be installed and running
   - Download from: https://www.docker.com/products/docker-desktop
   - Ensure Docker Desktop is **running** before proceeding

2. **Git** - For cloning the repository

3. **Windows PowerShell** or **Git Bash** - For running commands

4. **Minimum System Requirements:**
   - RAM: 8GB+ (Docker will use ~6GB)
   - Disk Space: 20GB+ free space
   - CPU: Multi-core recommended

## 🚀 Quick Start

### Step 1: Clone the Repository

```powershell
git clone https://github.com/pipeshub-ai/pipeshub-ai.git
cd pipeshub-ai
```

**Optional: If you have a fork and want to sync with the original repository:**

```powershell
# Add upstream remote (if not already added)
git remote add upstream https://github.com/pipeshub-ai/pipeshub-ai.git

# Verify remotes are configured
git remote -v

# Pull latest changes from upstream
git fetch upstream
git merge upstream/main
```

### Step 2: Configure Docker Desktop

**IMPORTANT:** Before starting, configure Docker Desktop:

1. Open **Docker Desktop**
2. Go to **Settings** → **Resources** → **Advanced**
3. Set **Memory** to **8GB** (or at least 6GB)
4. Click **Apply & Restart**

### Step 3: Check for Port Conflicts

Ensure these ports are available:
- `3000` - Frontend
- `8001` - Query/AI Service
- `8088` - Connector Service
- `8091` - Indexing Service
- `8081` - Docling Service
- `8529` - ArangoDB
- `27017` - MongoDB
- `6379` - Redis
- `9092` - Kafka
- `2181` - Zookeeper
- `6333` - Qdrant
- `2379` - etcd

**Check for conflicts:**
```powershell
netstat -ano | findstr ":3000 :8001 :8088 :8091 :8529 :27017 :6379 :9092 :2181"
```

If any ports are in use, stop the conflicting services or change ports in `docker-compose.dev.yml`.

### Step 4: Navigate to Deployment Directory

```powershell
cd deployment/docker-compose
```

### Step 5: Start the Services

```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai up -d
```

**First time setup (with build):**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai up --build -d
```

### Step 6: Verify Services are Running

```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai ps
```

All services should show `Up` status. Wait 1-2 minutes for full initialization.

### Step 7: Access the Application

Open your browser and navigate to:
- **Frontend**: http://localhost:3000

## 🔧 Common Issues and Solutions

### Issue 1: Port Already Allocated

**Error:** `Bind for 0.0.0.0:XXXX failed: port is already allocated`

**Solution:**
1. Find what's using the port:
   ```powershell
   netstat -ano | findstr ":XXXX"
   ```
2. Stop conflicting containers:
   ```powershell
   docker ps
   docker stop <container-name>
   ```
3. Or stop all Docker containers:
   ```powershell
   docker stop $(docker ps -q)
   ```

### Issue 2: Docker Desktop Not Running

**Error:** `The system cannot find the file specified` or connection errors

**Solution:**
1. Start Docker Desktop manually
2. Wait until Docker Desktop is fully started (icon in system tray should be steady)
3. Verify Docker is running:
   ```powershell
   docker ps
   ```

### Issue 3: AI Service Unavailable

**Error:** `AI Service is currently unavailable. Please check your network connection or try again later.`

**Solution:**
1. The Query service takes 1-2 minutes to fully initialize
2. Check if Query service is running:
   ```powershell
   docker compose -f docker-compose.dev.yml -p pipeshub-ai logs pipeshub-ai | Select-String "Uvicorn running.*8000"
   ```
3. Wait for the message: `INFO: Uvicorn running on http://0.0.0.0:8000`
4. Verify health endpoint:
   ```powershell
   docker exec pipeshub-ai-pipeshub-ai-1 curl -s http://localhost:8000/health
   ```
5. If still failing, check logs:
   ```powershell
   docker compose -f docker-compose.dev.yml -p pipeshub-ai logs pipeshub-ai --tail 50
   ```

### Issue 4: Out of Memory

**Error:** Container crashes or services fail to start

**Solution:**
1. Increase Docker Desktop memory limit to 8GB+
2. Check memory usage:
   ```powershell
   docker stats --no-stream
   ```
3. The main container is limited to 6GB in `docker-compose.dev.yml`

### Issue 5: Process Monitor Script Errors

**Error:** `process_monitor.sh: not found` or syntax errors

**Solution:**
1. Ensure `process_monitor.sh` exists in the project root
2. If missing, extract from container:
   ```powershell
   docker cp pipeshub-ai-pipeshub-ai-1:/app/process_monitor.sh process_monitor.sh
   ```
3. Fix line endings (if on Windows):
   ```powershell
   (Get-Content process_monitor.sh -Raw) -replace "`r`n", "`n" | Set-Content process_monitor.sh -NoNewline
   ```

### Issue 6: Merge Conflicts in Code

**Error:** `SyntaxError: invalid syntax` with `<<<<<<< Updated upstream`

**Solution:**
1. Pull latest from upstream:
   ```powershell
   git fetch upstream
   git pull upstream main
   ```
2. Resolve any merge conflicts manually
3. Rebuild container:
   ```powershell
   docker compose -f docker-compose.dev.yml -p pipeshub-ai up --build -d
   ```

## 📊 Monitoring Services

### View Logs

**All services:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs -f
```

**Specific service:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs -f pipeshub-ai
```

### Check Service Status

```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai ps
```

### Check Resource Usage

```powershell
docker stats --no-stream
```

### Test Health Endpoints

```powershell
# Query Service
docker exec pipeshub-ai-pipeshub-ai-1 curl -s http://localhost:8000/health

# Connector Service
docker exec pipeshub-ai-pipeshub-ai-1 curl -s http://localhost:8088/health

# Indexing Service
docker exec pipeshub-ai-pipeshub-ai-1 curl -s http://localhost:8091/health
```

## 🛑 Stopping Services

```powershell
cd deployment/docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai down
```

**Stop and remove volumes (clean slate):**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai down -v
```

## 🔄 Restarting Services

```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart
```

**Restart specific service:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart pipeshub-ai
```

## 🧹 Cleanup

### Remove Unused Docker Resources

```powershell
docker system prune -a --volumes
```

**Warning:** This removes all unused containers, images, and volumes.

### Clean Build (Fresh Start)

```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai down -v
docker compose -f docker-compose.dev.yml -p pipeshub-ai up --build -d
```

## 📝 Environment Variables

Optional: Create a `.env` file in `deployment/docker-compose/` directory:

```env
NODE_ENV=development
LOG_LEVEL=info
ALLOWED_ORIGINS=

SECRET_KEY=your_random_encryption_secret_key

CONNECTOR_PUBLIC_BACKEND=
FRONTEND_PUBLIC_URL=

ARANGO_PASSWORD=your_arangodb_password
REDIS_PASSWORD=
MONGO_USERNAME=admin
MONGO_PASSWORD=your_mongodb_password
QDRANT_API_KEY=your_qdrant_api_key
```

See `env.template` for all available options.

## ✅ Verification Checklist

Before using the application, verify:

- [ ] Docker Desktop is running
- [ ] All containers are `Up` (check with `docker compose ps`)
- [ ] Ports 3000, 8001, 8088, 8091 are listening
- [ ] Query service shows: `Uvicorn running on http://0.0.0.0:8000` in logs
- [ ] Health endpoints return `{"status":"healthy"}`
- [ ] Frontend loads at http://localhost:3000
- [ ] No "Restarting Query service" messages in logs

## 🆘 Troubleshooting

### Services Won't Start

1. Check Docker Desktop is running
2. Verify ports are not in use
3. Check Docker has enough memory (8GB+)
4. Review logs: `docker compose logs`

### Query Service Keeps Restarting

1. Wait 2-3 minutes for full initialization
2. Check logs for errors: `docker compose logs pipeshub-ai`
3. Verify health endpoint: `curl http://localhost:8001/health`
4. The service needs time to:
   - Connect to databases
   - Discover and register 152 tools
   - Load embedding models
   - Start Kafka consumers

### Frontend Shows Empty Page

1. Hard refresh browser (Ctrl+F5)
2. Check browser console for errors (F12)
3. Verify Node.js service is running:
   ```powershell
   docker exec pipeshub-ai-pipeshub-ai-1 ps aux | findstr "node"
   ```
4. Check frontend logs:
   ```powershell
   docker compose logs pipeshub-ai | Select-String "Node.js"
   ```

## 📚 Additional Resources

- Main README: [README.md](../README.md)
- Contributing Guide: [CONTRIBUTING.md](../CONTRIBUTING.md)
- Docker Compose Docs: https://docs.docker.com/compose/

## 🎯 Quick Reference

**Start:**
```powershell
cd deployment/docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai up -d
```

**Stop:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai down
```

**View Logs:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs -f
```

**Restart:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart
```

**Access:**
- Frontend: http://localhost:3000
- Query API: http://localhost:8001
- Connector API: http://localhost:8088
- Indexing API: http://localhost:8091

---

**Note:** The first startup may take 2-3 minutes as services initialize, especially the Query service which needs to discover tools and load models. Be patient and monitor the logs.

