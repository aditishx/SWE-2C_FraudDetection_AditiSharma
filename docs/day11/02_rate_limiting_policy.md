# Rate Limiting Policy — 5-Tier Framework

**Day 11 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 9 July 2026

> Rate limiting protects the platform from two threats simultaneously:
> (1) enumeration attacks — fraudsters testing stolen card numbers at high volume,
> (2) accidental overload — a merchant sending traffic spikes beyond contracted limits.
> All counters are stored in Redis with atomic increment to ensure correctness
> across multiple Kong gateway instances.

---

## The 5 Tiers

### Tier 1 — Per-Merchant (contracted throughput)

Prevents any single merchant from exceeding their contracted capacity.

| Merchant tier | Limit | Window |
|---|---|---|
| Large acquirer (e.g. Razorpay, PayU) | 1,000 req/min | Rolling 60s |
| Mid-size merchant | 300 req/min | Rolling 60s |
| Small merchant | 100 req/min | Rolling 60s |
| Default (unclassified) | 60 req/min | Rolling 60s |

```yaml
# Kong plugin config for per-merchant limiting
- name: rate-limiting-advanced
  config:
    limit: [1000]              # large acquirer tier
    window_size: [60]
    identifier: consumer       # consumer = merchant JWT sub claim
    dictionary_name: kong_rate_limiting_counters
    sync_rate: 0.1             # sync Redis counters every 100ms
    namespace: merchant_tier
    hide_client_headers: false # expose X-RateLimit-* headers
```

### Tier 2 — Per-IP (distributed attack detection)

Detects distributed enumeration attacks where a fraud ring uses many
merchant accounts to spread load, but originates from a limited IP range.

| Limit | Window | Action on breach |
|---|---|---|
| 50 req/min per IP | Rolling 60s | 429 response + alert |
| 200 req/10min per IP | Rolling 600s | Temporary IP block (10 min) + P2 alert |

```yaml
- name: rate-limiting-advanced
  config:
    limit: [50, 200]
    window_size: [60, 600]
    identifier: ip
    namespace: per_ip
```

### Tier 3 — Per-Endpoint (endpoint-specific limits)

Different endpoints have different risk profiles and capacity costs.

| Endpoint | Limit | Window | Reason |
|---|---|---|---|
| POST /api/v1/transactions | 1,000/min per merchant | 60s | Core path — merchant-tier governed |
| GET /api/v1/transactions/*/risk-score | 5,000/min per consumer | 60s | Read-only, cached — can be higher |
| GET /api/v1/cases | 500/min per consumer | 60s | Analyst tool — human-paced |
| PUT /api/v1/cases/*/decision | 200/min per consumer | 60s | Write — lower limit |
| POST /api/v1/rules | 100/min per consumer | 60s | Rule authoring — infrequent |
| GET /api/v1/dashboard/metrics | 60/min per consumer | 60s | Cached 30s — no need for high limit |

### Tier 4 — Global (system-wide capacity protection)

Protects the entire backend from total overload regardless of how traffic
is distributed across merchants and IPs.

| Limit | Window | Action on breach |
|---|---|---|
| 50,000 req/min total (all routes) | Rolling 60s | 503 Service Unavailable + P1 alert |

```yaml
- name: rate-limiting-advanced
  config:
    limit: [50000]
    window_size: [60]
    identifier: service    # global — not per-consumer or per-IP
    namespace: global_cap
```

### Tier 5 — Adaptive (fraud-spike response)

Dynamically tightens limits when fraud rate spikes, preventing fraudsters from
using a rate limit window to maximise damage before detection.

```
Trigger: fraud_rate_last_5min > 5% (Prometheus metric)

Action:
  1. Prometheus alert fires → webhook calls Kong Admin API
  2. Per-merchant limits reduced by 50% for all merchants
  3. Per-IP limits reduced by 60%
  4. P2 alert sent to #fraud-ops Slack channel
  5. Limits restored automatically when fraud_rate drops below 3%
     (hysteresis prevents flapping)

Implementation:
  - Prometheus alerting rule fires on fraud_rate > 5%
  - Alert webhook hits Kong Admin API: PATCH /consumers/{id}/plugins/rate-limiting
  - Kubernetes CronJob checks every 60s to restore limits when condition clears
```

---

## Redis Counter Architecture

All rate limit counters use Redis with atomic `INCR` + `EXPIRE` operations:

```
Key pattern:  rl:{namespace}:{identifier}:{window_start_unix}
Example:      rl:merchant_tier:merchant_razorpay:1751452800
Value:        integer (current count in window)
TTL:          window_size + 30s buffer

Why atomic INCR:
  Multiple Kong pods increment the same counter simultaneously.
  Redis single-threaded atomic INCR guarantees no race condition.
  Alternative (in-memory per-pod counters) would allow each pod
  to independently allow up to the limit → actual throughput = limit × pod_count.
```

---

## Response Headers

Every rate-limited response includes:

```
X-RateLimit-Limit-Minute: 1000
X-RateLimit-Remaining-Minute: 847
X-RateLimit-Reset: 1751452860
Retry-After: 23          # seconds until window resets (429 responses only)
```

Clients use these to self-regulate — a well-behaved client slows down
before hitting the limit rather than discovering it via 429 errors.

---

## Circuit Breaker at Gateway Level

Per Section A3.2, the gateway implements a circuit breaker per upstream service:

```yaml
# Kong Circuit Breaker configuration per upstream
upstreams:
  - name: transaction-ingestion-upstream
    healthchecks:
      passive:
        healthy:
          successes: 5
        unhealthy:
          http_failures: 5      # 5 consecutive 5xx → circuit opens
          timeouts: 3
      active:
        http_path: /healthz
        interval: 5             # probe every 5s when circuit is open
        healthy:
          successes: 2          # 2 successful probes → circuit closes
```

**Circuit states:**
- **Closed** (normal): all requests pass through
- **Open** (failure detected): immediate 503, no requests forwarded; downstream gets breathing room
- **Half-open** (recovery probe): 1 request forwarded; if successful, circuit closes

**Per-service circuit breaker thresholds:**

| Service | Open trigger | Recovery probe interval |
|---|---|---|
| transaction-ingestion-svc | 5 consecutive 5xx in 10s | 5s |
| rule-engine-svc | 3 consecutive 5xx in 10s | 5s |
| risk-scoring-svc | 3 consecutive 5xx in 10s | 5s |
| case-management-svc | 10 consecutive 5xx in 30s | 10s |
| notification-svc | N/A (async Kafka path) | — |
