# Kente Retail — Order Service

Minimal HTTP service backing Kente Retail's order pipeline (sandbox copy for training).

## Running locally

```bash
npm start
```

Serves on port 8080 by default (override with `PORT`).

- `GET /health` — liveness check
- `GET /api/orders?status=<status>` — list orders, optional status filter (returns 503 if DB is unreachable)


## Deployment

Deployed to `/opt/kente-retail/app` on the application server. See the ops team's
server-baseline-policy for the expected permissions, users, and hostname convention.
