# Day 11 Work Log — API Gateway and Rate Limiting Design

**Date:** 9 July 2026
**Commit tag:** `Day11_Gateway_Design`

## What I did
- Wrote complete Kong declarative configuration for all 5 external REST routes
  with per-route plugins (auth, rate limiting, validation, caching, transcoding).
- Designed 5-tier rate limiting framework with Redis-backed atomic counters:
  per-merchant, per-IP, per-endpoint, global, and adaptive (fraud-spike response).
- Documented atomic Redis INCR pattern and why in-memory per-pod counters
  would allow limit × pod_count actual throughput (incorrect).
- Wrote 3 authentication flow diagrams (JWT primary, API Key legacy, analyst
  role-based) with token refresh flow.
- Designed per-service circuit breaker thresholds with distinct open triggers
  and recovery probe intervals based on each service's criticality.

## Key decisions made
1. **Adaptive rate limiting (Tier 5) reduces limits when fraud rate >5%** —
   directly from Section A3.2. If fraudsters are exploiting a rate limit window,
   tightening limits by 50-60% mid-attack reduces the damage window without
   requiring a code deployment.
2. **Response caching for GET /risk-score (5s TTL)** — retry-happy clients
   (e.g. a payment terminal retrying a declined transaction immediately) would
   hammer the risk scoring service. 5-second cache absorbs retries transparently.
3. **Dashboard metrics cached for 30s** — dashboards don't need sub-second
   freshness; 30s cache dramatically reduces analytics service load during
   high-traffic periods when dashboards are refreshed most frequently.
4. **API Key auth marked for phase-out** — documented as legacy-only in the
   config. Every new integration must use JWT. API Keys are audited quarterly
   and migrated to JWT on each renewal.

## Tomorrow's plan (Day 12)
- Design 4 Grafana dashboards with all panel specifications.
- Write Prometheus recording rules and alerting rules (P1-P4).
- Write Alertmanager routing config.
- Write P1 and P2 runbooks with diagnosis and remediation steps.
