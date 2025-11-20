# PipesHub AI - Quick Start Guide

## ⚡ Quick Launch (5 Steps)

### 1. Prerequisites Check
- ✅ Docker Desktop installed and **RUNNING**
- ✅ At least 8GB RAM available for Docker
- ✅ Ports 3000, 8001, 8088, 8091, 8529, 27017, 6379, 9092, 2181 are free

### 2. Configure Docker Desktop Memory
1. Open Docker Desktop
2. Settings → Resources → Advanced
3. Set Memory to **8GB** (minimum 6GB)
4. Apply & Restart

### 3. Check Port Conflicts
```powershell
netstat -ano | findstr ":3000 :8001 :8088 :8091"
```
If ports are in use, stop conflicting services:
```powershell
docker stop $(docker ps -q)
```

### 4. Start the Project
```powershell
cd deployment/docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai up -d
```

**First time (with build):**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai up --build -d
```

### 5. Wait and Access
- **Wait 2-3 minutes** for services to fully initialize
- Open browser: **http://localhost:3000**

## ✅ Verify Everything Works

```powershell
# Check all services are running
docker compose -f docker-compose.dev.yml -p pipeshub-ai ps

# Check Query service is ready (should show "Uvicorn running on http://0.0.0.0:8000")
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs pipeshub-ai --tail 20 | Select-String "Uvicorn running"

# Test health endpoints
docker exec pipeshub-ai-pipeshub-ai-1 curl -s http://localhost:8000/health
```

## 🛑 Common Issues

### "Port already allocated"
```powershell
# Find and stop conflicting containers
docker ps
docker stop <container-name>
```

### "Docker Desktop not running"
- Start Docker Desktop manually
- Wait until fully started (system tray icon steady)

### "AI Service unavailable"
- **Wait 2-3 minutes** - Query service takes time to initialize
- Check logs: `docker compose -f docker-compose.dev.yml -p pipeshub-ai logs pipeshub-ai`
- Look for: `INFO: Uvicorn running on http://0.0.0.0:8000`

### Services keep restarting
- Check Docker has enough memory (8GB+)
- Wait longer - first startup takes 2-3 minutes
- Check logs for errors

## 📊 Useful Commands

**View logs:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs -f
```

**Stop services:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai down
```

**Restart services:**
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart
```

**Check resource usage:**
```powershell
docker stats --no-stream
```

## 🎯 Service URLs

- **Frontend**: http://localhost:3000
- **Query/AI API**: http://localhost:8001
- **Connector API**: http://localhost:8088
- **Indexing API**: http://localhost:8091
- **Docling API**: http://localhost:8081

## ⚠️ Important Notes

1. **First startup takes 2-3 minutes** - Be patient!
2. **Query service needs time** to:
   - Discover 152 tools
   - Load embedding models
   - Connect to all databases
3. **Don't restart** during initialization - wait for "Uvicorn running" message
4. **Docker Desktop must be running** before starting services

## 🆘 Still Having Issues?

See the full [SETUP_GUIDE.md](../../SETUP_GUIDE.md) for detailed troubleshooting.




