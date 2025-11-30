# How to Restart Containers to See Frontend Changes

## Quick Restart (After Code Changes)

Since you made changes to the frontend code, you need to rebuild the container:

```powershell
cd C:\pipeshub\pipeshub-ai\deployment\docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai up -d --build pipeshub-ai
```

This will:
- Rebuild the frontend container with your changes
- Restart the pipeshub-ai service
- Keep all other services running

## View Logs to Verify Changes

After restarting, check the logs:

```powershell
docker compose -f docker-compose.dev.yml -p pipeshub-ai logs -f pipeshub-ai
```

## Alternative: Restart All Services

If you need to restart everything:

```powershell
cd C:\pipeshub\pipeshub-ai\deployment\docker-compose
docker compose -f docker-compose.dev.yml -p pipeshub-ai restart
```

## Note on TypeScript Errors

If you're seeing TypeScript errors in your IDE:
1. The container will still build and run if there are only warnings
2. To fix the errors before restarting, run: `cd pipeshub-ai/frontend && npm run lint:fix`
3. Or fix them manually in your IDE

