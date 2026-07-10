# Authentication Flow Diagrams

**Day 11 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 9 July 2026

---

## Flow 1 — JWT (Primary: Merchant to Platform)

```mermaid
sequenceDiagram
    participant M as Merchant System
    participant IDP as Identity Provider (Keycloak)
    participant GW as Kong API Gateway
    participant SVC as transaction-ingestion-svc

    M->>IDP: POST /oauth/token (client_credentials grant)\nclient_id + client_secret
    IDP-->>M: access_token (JWT, RS256 signed, exp: 15 min)\nclaims: {sub: merchant_id, roles: [submit_transaction], market: IN}

    M->>GW: POST /api/v1/transactions\nAuthorization: Bearer <JWT>
    GW->>GW: Validate JWT signature\n(RS256 public key from JWKS endpoint)
    GW->>GW: Check exp claim not expired
    GW->>GW: Check roles includes submit_transaction
    GW->>GW: Rate limit check (Tier 1 + Tier 2 + Tier 3)
    GW->>GW: Inject X-Merchant-ID: merchant_id header
    GW->>GW: Inject X-Correlation-ID: uuid
    GW->>SVC: Forward request via gRPC transcoding\n(merchant identity already verified)
    SVC-->>GW: gRPC response (RiskDecision)
    GW-->>M: HTTP 200 (TransactionDecisionResponse)\n+ X-RateLimit-* headers
```

---

## Flow 2 — API Key (Legacy Integrations Only)

```mermaid
sequenceDiagram
    participant L as Legacy System
    participant GW as Kong API Gateway
    participant REDIS as Redis (key store)
    participant SVC as transaction-ingestion-svc

    Note over L,GW: API Keys issued manually via Kong Admin API.\nTo be phased out — JWT is preferred.

    L->>GW: POST /api/v1/transactions\nX-API-Key: <api_key>
    GW->>REDIS: GET key:{hash(api_key)}
    REDIS-->>GW: {merchant_id, roles, rate_limit_tier}
    GW->>GW: Rate limit check\nInject X-Merchant-ID header\nInject X-Correlation-ID header
    GW->>SVC: Forward request
    SVC-->>GW: Response
    GW-->>L: HTTP 200 + X-RateLimit-* headers
```

---

## Flow 3 — Analyst Dashboard (Role-Based JWT)

```mermaid
sequenceDiagram
    participant A as Fraud Analyst (browser)
    participant IDP as Keycloak
    participant GW as Kong API Gateway
    participant CM as case-management-svc

    A->>IDP: Login (username + OTP)\nRoles assigned: [analyst, case_viewer]
    IDP-->>A: access_token (JWT)\nclaims: {sub: analyst_id, roles: [analyst, case_viewer]}

    A->>GW: GET /api/v1/cases?status=OPEN\nAuthorization: Bearer <JWT>
    GW->>GW: Validate JWT\nCheck roles includes case_viewer
    GW->>CM: Forward GET /cases?status=OPEN
    CM-->>GW: Paginated case list
    GW-->>A: HTTP 200 (CaseListResponse)

    A->>GW: PUT /api/v1/cases/case_001/decision\nAuthorization: Bearer <JWT>\n{decision: CONFIRMED_FRAUD}
    GW->>GW: Check roles includes analyst\n(required for PUT /cases/*/decision)
    GW->>CM: Forward PUT /cases/case_001/decision
    CM-->>GW: Decision recorded
    GW-->>A: HTTP 200 (CaseDecisionResponse)
```

---

## Token Refresh Flow

```mermaid
sequenceDiagram
    participant C as Client (Merchant/Analyst)
    participant IDP as Keycloak

    Note over C: access_token expires (15 min TTL)

    C->>IDP: POST /oauth/token\ngrant_type=refresh_token\nrefresh_token=<refresh_token>
    IDP->>IDP: Validate refresh token\n(24h TTL, single-use, rotated on each use)
    IDP-->>C: New access_token (15 min)\nNew refresh_token (24h, replaces old)

    Note over C: Seamless — user/system never re-authenticates\nuntil refresh_token expires (24h)
```
