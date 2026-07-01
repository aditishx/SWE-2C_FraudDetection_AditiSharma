# Service SLA Specification Table

**Day 3 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 30 June 2026

---

## Tier 1 — Critical Path

| Service | p50 | p95 | p99 | Availability | Throughput | Error Budget Policy | Dependencies |
|---|---|---|---|---|---|---|---|
| transaction-ingestion-svc | <15ms | <40ms | <80ms | 99.99% | 50,000 TPS | Freeze non-critical deploys; page on-call | ThreatMetrix, MaxMind |
| rule-engine-svc | <5ms | <20ms | <50ms | 99.99% | 50,000 TPS | Freeze deploys; alert CRO | Kafka lag <5ms from ingestion |
| anomaly-detection-svc | <8ms | <20ms | <30ms | 99.99% | 50,000 TPS | Fall back to rule-only scoring | Redis feature store <1ms |
| graph-analysis-svc | <10ms | <30ms | <50ms | 99.9% | 10,000 TPS (real-time path) | Fall back to rule+ML + score safety margin | Neo4j read replica |
| risk-scoring-svc | <5ms | <15ms | <25ms | 99.99% | 50,000 TPS | P1 escalation immediately | All 3 detection services above |

## Tier 2 — Supporting Services

| Service | p50 | p95 | p99 | Availability | Throughput | Error Budget Policy |
|---|---|---|---|---|---|---|
| case-management-svc | <100ms | <300ms | <500ms | 99.9% | 500 TPS | Alert Fraud Ops; case queue grows but transactions unaffected |
| notification-svc | <200ms | <1s | <3s | 99.9% | 5,000 TPS | Retry queue; alert Infra team |
| customer-profile-svc | <5ms | <15ms | <30ms | 99.9% | 20,000 TPS | AD falls back to population-average features |
| reference-data-svc | <2ms | <5ms | <10ms | 99.99% | 50,000 TPS (Redis cached) | Rule Engine uses last cached values (max 5min staleness) |

## Tier 3 — Non-Critical

| Service | p50 write | p99 query | Availability | Error Budget Policy |
|---|---|---|---|---|
| audit-compliance-svc | <50ms | <500ms | 99.9% | Writes queue in Kafka (infinite retention) — no data lost, just delayed |

## End-to-end pipeline SLA

| Metric | Target |
|---|---|
| Full pipeline latency (ingestion → risk decision) | p50 <50ms · p95 <150ms · p99 <200ms |
| Fraud detection rate | >95% of known fraud flagged |
| False positive rate | <0.5% of legitimate transactions flagged |
| System availability (critical path) | 99.99% |
| Kafka consumer lag (critical path partitions) | <1,000 messages/partition steady state |
| Model inference latency | p99 <10ms |
| Graph query latency (real-time path) | p99 <50ms |

## Fallback table (when a service breaches its SLA)

| Service unavailable | Fallback behaviour |
|---|---|
| anomaly-detection-svc | Rule + Graph signals only; approval threshold lowered by 20% (conservative) |
| graph-analysis-svc | Rule + ML signals only; composite score +100 points safety margin |
| customer-profile-svc | Anomaly Detection uses population-average feature values |
| reference-data-svc | Last Redis-cached values (max 5 min staleness) |
| notification-svc | Notifications queued in Kafka; delivered on recovery |
