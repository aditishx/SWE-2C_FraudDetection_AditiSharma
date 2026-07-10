# API Gateway Configuration

**Day 11 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 9 July 2026

> Gateway: **Kong** (self-hosted on Kubernetes via Kong Ingress Controller).
> Kong sits at the perimeter — the single entry point for all external traffic.
> All internal service-to-service traffic bypasses the gateway entirely
> and goes through Istio mTLS directly.

---

## Gateway Responsibilities

| Responsibility | Mechanism | Config location |
|---|---|---|
| TLS termination | TLS 1.3 (minimum), public CA cert | Kong TLS plugin |
| JWT authentication | RS256 validation against JWKS endpoint | Kong JWT plugin |
| API Key authentication | Redis key store lookup | Kong Key-Auth plugin |
| OAuth 2.0 (M2M) | Keycloak token introspection | Kong OAuth2 plugin |
| Rate limiting | 5-tier Redis-backed counters | Kong Rate-Limiting-Advanced plugin |
| Request validation | OpenAPI spec validation before forwarding | Kong Request-Validator plugin |
| Request transformation | REST → gRPC transcoding | Kong gRPC-Gateway plugin |
| Response caching | Cache risk score GETs for 5 seconds | Kong Proxy-Cache plugin |
| Correlation ID injection | Generates trace_id if not present | Kong Correlation-ID plugin |
| Access logging | Structured JSON logs per request | Kong File-Log plugin → Fluentd |
| Circuit breaking | 503 after 50% error rate in 10s window | Kong Circuit-Breaker plugin |

---

## Route Configuration

```yaml
# Kong Declarative Config (kong.yaml)
# Each route maps an external REST path to an internal upstream

_format_version: "3.0"

services:

  # ── Transaction submission ─────────────────────────────────────────────
  - name: transaction-ingestion
    url: grpc://transaction-ingestion-svc.fraud-detection.svc.cluster.local:8080
    connect_timeout: 10000    # 10ms
    write_timeout: 90000      # 90ms (within 100ms SLA)
    read_timeout: 90000
    routes:
      - name: submit-transaction
        paths: ["/api/v1/transactions"]
        methods: ["POST"]
        strip_path: false
    plugins:
      - name: jwt
        config:
          key_claim_name: sub
          claims_to_verify: [exp]
      - name: key-auth
        config:
          key_names: ["X-API-Key"]
          hide_credentials: true
      - name: request-validator
        config:
          body_schema: '{"$ref": "#/components/schemas/TransactionRequest"}'
      - name: rate-limiting-advanced
        config:
          limit: [1000]
          window_size: [60]
          identifier: consumer
          sync_rate: 0.1
          namespace: txn_submit

  # ── Risk score retrieval ───────────────────────────────────────────────
  - name: risk-score-retrieval
    url: http://risk-scoring-svc.fraud-detection.svc.cluster.local:8080
    connect_timeout: 5000
    write_timeout: 100000
    read_timeout: 100000
    routes:
      - name: get-risk-score
        paths: ["/api/v1/transactions/(?<transaction_id>[^/]+)/risk-score"]
        methods: ["GET"]
    plugins:
      - name: jwt
      - name: proxy-cache
        config:
          response_code: [200]
          request_method: ["GET"]
          cache_ttl: 5           # 5-second cache — handles retry-happy clients
          cache_control: false
      - name: rate-limiting-advanced
        config:
          limit: [5000]
          window_size: [60]
          identifier: consumer
          namespace: risk_score_get

  # ── Case management ────────────────────────────────────────────────────
  - name: case-management
    url: http://case-management-svc.fraud-detection.svc.cluster.local:8080
    connect_timeout: 50000
    write_timeout: 500000
    read_timeout: 500000
    routes:
      - name: list-cases
        paths: ["/api/v1/cases"]
        methods: ["GET"]
      - name: record-decision
        paths: ["/api/v1/cases/(?<case_id>[^/]+)/decision"]
        methods: ["PUT"]
    plugins:
      - name: jwt
        config:
          claims_to_verify: [exp, roles]   # roles claim checked for analyst/manager
      - name: rate-limiting-advanced
        config:
          limit: [500]
          window_size: [60]
          identifier: consumer
          namespace: case_mgmt

  # ── Rule management ────────────────────────────────────────────────────
  - name: rule-management
    url: http://rule-engine-svc.fraud-detection.svc.cluster.local:8080
    connect_timeout: 10000
    write_timeout: 200000
    read_timeout: 200000
    routes:
      - name: list-rules
        paths: ["/api/v1/rules"]
        methods: ["GET"]
      - name: create-rule
        paths: ["/api/v1/rules"]
        methods: ["POST"]
    plugins:
      - name: jwt
      - name: rate-limiting-advanced
        config:
          limit: [100]
          window_size: [60]
          identifier: consumer
          namespace: rule_mgmt

  # ── Dashboard metrics ──────────────────────────────────────────────────
  - name: dashboard-metrics
    url: http://analytics-svc.fraud-detection.svc.cluster.local:8080
    connect_timeout: 50000
    write_timeout: 2000000
    read_timeout: 2000000
    routes:
      - name: get-metrics
        paths: ["/api/v1/dashboard/metrics"]
        methods: ["GET"]
    plugins:
      - name: jwt
      - name: proxy-cache
        config:
          cache_ttl: 30          # 30-second cache — dashboard doesn't need sub-second freshness
          request_method: ["GET"]
          response_code: [200]
      - name: rate-limiting-advanced
        config:
          limit: [60]
          window_size: [60]
          identifier: consumer
          namespace: dashboard

# Global plugins (apply to all routes)
plugins:
  - name: correlation-id
    config:
      header_name: X-Correlation-ID
      generator: uuid#counter
      echo_downstream: true

  - name: file-log
    config:
      path: /dev/stdout     # stdout → Fluentd picks up and ships to Elasticsearch
      reopen: false

  - name: prometheus
    config:
      per_consumer: true    # per-consumer metrics for rate limit monitoring
