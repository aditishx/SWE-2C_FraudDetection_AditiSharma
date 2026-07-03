# API Gateway Routing Configuration

**Day 5 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 2 July 2026

## Routing table — external REST to internal gRPC

The API Gateway (Kong) translates every inbound REST call into an internal gRPC
call using a transcoding layer (grpc-gateway or Kong's gRPC plugin).

| External REST Endpoint | Method | Internal gRPC Target | Timeout | Auth |
|---|---|---|---|---|
| `/api/v1/transactions` | POST | `transaction-ingestion-svc:8080` → gRPC `IngestTransaction` | 200ms | JWT (RS256) or API Key |
| `/api/v1/transactions/{id}/risk-score` | GET | `risk-scoring-svc:8080` → PostgreSQL read | 100ms | JWT |
| `/api/v1/cases` | GET | `case-management-svc:8080` → REST passthrough | 500ms | JWT (role: analyst, manager) |
| `/api/v1/cases/{id}/decision` | PUT | `case-management-svc:8080` → REST passthrough | 500ms | JWT (role: analyst) |
| `/api/v1/rules` | GET | `rule-engine-svc:8080` → Rule Management API | 200ms | JWT (role: analyst, manager) |
| `/api/v1/rules` | POST | `rule-engine-svc:8080` → Rule Management API | 200ms | JWT (role: analyst) |
| `/api/v1/dashboard/metrics` | GET | `analytics-svc:8080` → materialised views | 2000ms | JWT (role: analyst, manager, director) |

## Rate limiting tiers (per Section A3.2)

| Tier | Scope | Limit | Storage |
|---|---|---|---|
| Per-merchant | Based on contracted throughput | 1,000 TPS (large acquirer) / 100 TPS (small merchant) | Redis atomic counter |
| Per-IP | Distributed attack detection | 50 req/min | Redis atomic counter |
| Per-endpoint | `/api/v1/transactions` POST stricter than GET | 1,000/min POST, 5,000/min GET | Redis atomic counter |
| Global | Protect backend from total overload | 50,000 TPS | Redis atomic counter |
| Adaptive | Tighten automatically on fraud spike | If fraud rate >5%: reduce per-merchant limit by 50% | Prometheus metric → Kong plugin |

Response headers on every request:
```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 847
X-RateLimit-Reset: 1751452800
```

## Authentication flows

### Flow 1 — JWT (primary, merchant to platform)
```
Merchant → POST /api/v1/transactions
  + Authorization: Bearer <JWT>
    ↓
Kong validates JWT signature (RS256, public key from JWKS endpoint)
Kong extracts claims: sub=merchant_id, roles=[submit_transaction], exp
Kong injects X-Merchant-ID header to downstream service
  ↓
transaction-ingestion-svc receives request (merchant_id already verified)
```

### Flow 2 — API Key (legacy integrations only)
```
Legacy system → POST /api/v1/transactions
  + X-API-Key: <key>
    ↓
Kong validates key against Redis key store
Kong maps key to merchant_id and role set
Same downstream flow as JWT
```

### Flow 3 — OAuth 2.0 client credentials (machine-to-machine)
```
Internal service (e.g. analytics dashboard) → GET /api/v1/dashboard/metrics
  + Authorization: Bearer <OAuth2 access token>
    ↓
Kong validates token against internal OAuth server (Keycloak)
Scope: read:metrics
```

## Circuit breaker at gateway level

If downstream error rate for a route exceeds 50% over a 10-second window:
- Circuit opens for that route only (other routes unaffected)
- Returns 503 with `Retry-After` header
- Circuit attempts recovery after 30 seconds (half-open: 1 probe request)
- Alert: P2 to Slack #alerts channel
