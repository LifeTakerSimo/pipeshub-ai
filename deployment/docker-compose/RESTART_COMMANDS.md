# Quick Restart Commands

## Just Restart the Application Service (No Code Changes)
```powershell
cd C:\pipeshub\pipeshub-ai\deployment\docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart pipeshub-ai
```

## Restart and Rebuild (After Code Changes)
```powershell
cd C:\pipeshub\pipeshub-ai\deployment\docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai up -d --build pipeshub-ai
```

## Restart Everything (All Services)
```powershell
cd C:\pipeshub\pipeshub-ai\deployment\docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart
```

## View Logs After Restart
```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs -f pipeshub-ai
```

