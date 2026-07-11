# SLA Specification — Final Formalised Document

**Day 13 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Date:** 11 July 2026

---

## 1. End-to-End Pipeline SLA

| Metric | Target | Measurement method | Measurement frequency |
|---|---|---|---|
| Pipeline latency p50 | < 50ms | `fraud:pipeline_latency_p50:5m` Prometheus recording rule | Continuous |
| Pipeline latency p95 | < 150ms | `fraud:pipeline_latency_p95:5m` | Continuous |
| Pipeline latency p99 | < 200ms | `fraud:pipeline_latency_p99:5m` | Continuous |
| Fraud detection rate | > 95% of known fraud flagged | Monthly reconciliation vs confirmed chargeback data | Monthly |
| False positive rate | < 0.5% of legitimate transactions | Analyst decision outcomes (case resolution data) | Weekly |
| System availability (critical path) | 99.99% | `1 - (downtime_minutes / 525,600)` per year | Monthly |
| System availability (non-critical) | 99.9% | Same formula | Monthly |
| Kafka consumer lag (critical path) | < 1,000 messages/partition | `fraud:kafka_lag_max:critical_path` | Continuous |

---

## 2. Per-Service SLA (formalised from Day 3 draft)

### Tier 1 — Critical Path

| Service | p99 latency | Availability | Throughput | Error budget (monthly) |
|---|---|---|---|---|
| transaction-ingestion-svc | < 80ms | 99.99% | 50,000 TPS | 4.38 min downtime |
| rule-engine-svc | < 50ms | 99.99% | 50,000 TPS | 4.38 min downtime |
| anomaly-detection-svc | < 30ms | 99.99% | 50,000 TPS | 4.38 min downtime |
| graph-analysis-svc (real-time) | < 50ms | 99.9% | 10,000 TPS | 43.8 min downtime |
| risk-scoring-svc | < 25ms | 99.99% | 50,000 TPS | 4.38 min downtime |

### Tier 2 — Supporting Services

| Service | p99 latency | Availability | Throughput | Error budget (monthly) |
|---|---|---|---|---|
| case-management-svc | < 500ms | 99.9% | 500 TPS | 43.8 min downtime |
| notification-svc | < 3s | 99.9% | 5,000 TPS | 43.8 min downtime |
| customer-profile-svc | < 30ms | 99.9% | 20,000 TPS | 43.8 min downtime |
| reference-data-svc | < 10ms | 99.99% | 50,000 TPS (cached) | 4.38 min downtime |

### Tier 3 — Non-Critical

| Service | p99 write latency | p99 query latency | Availability |
|---|---|---|---|
| audit-compliance-svc | < 50ms | < 500ms | 99.9% |

---

## 3. Error Budget Policy

An error budget is the allowed failure budget before corrective action is required.
99.99% availability = 4.38 minutes downtime per month = the error budget.

| Error budget consumed | Action |
|---|---|
| 0–50% | Normal operations — no action required |
| 50–75% | Engineering review of reliability risks this month |
| 75–100% | Freeze all non-critical feature deployments; focus on reliability |
| 100% (budget exhausted) | Hard freeze on ALL deployments until next monthly reset; post-mortem required |

Error budget is tracked per service in Grafana Dashboard 1 (Infrastructure panel).

---

## 4. Measurement Methodology

### Latency
- Measured end-to-end via OpenTelemetry distributed traces (trace_id propagated from ingestion to risk decision)
- Stored in Jaeger (30-day hot retention)
- Aggregated into Prometheus recording rules every 15 seconds
- Reported as p50/p95/p99 percentiles (not averages — averages hide tail latency)

### Availability
- Measured as: `1 - (time_with_zero_successful_requests / total_time)`
- A service is "down" when its error rate exceeds 50% for a sustained 1-minute window
- Measured by Prometheus `up` metric per service
- Monthly availability report generated automatically from Prometheus data

### Fraud detection rate
- Measured monthly by reconciling `fraud_decisions_total{action="AUTO_DECLINE"}` against confirmed chargebacks received from card networks
- 30-90 day lag from card networks is unavoidable (chargeback investigation takes time)
- Supplemented by ML model monitoring (PSI/KS drift) as an early-warning proxy

### False positive rate
- Measured from case management outcomes: `false_positive_confirmed / total_cases_resolved`
- Updated weekly as analysts resolve cases
- Also tracked per-rule via `rule_false_positive_rate` Prometheus metric (updated in real time from case decisions)

---

## 5. SLA Breach Response Matrix

| Severity | Breach condition | Response | Owner |
|---|---|---|---|
| P1 | p99 latency >200ms for >5 minutes | Immediate page; all hands investigation | On-call SRE + Platform Lead |
| P1 | Availability <99.9% in rolling 1-hour window | Immediate page; incident commander declared | On-call SRE + CTO |
| P2 | p99 latency 150-200ms for >5 minutes | Slack alert; investigation within 30 minutes | On-call SRE |
| P2 | Any service error rate >1% for >5 minutes | Slack alert; investigate within 30 minutes | Service owner |
| P3 | False positive rate >0.6% (20% above 0.5% target) | Daily digest; review in next sprint | Fraud Rules Team |
| P3 | Fraud detection rate <93% (monthly) | Review in weekly fraud ops meeting | CRO + ML Team |

---

## 6. Latency Budget Justification (Latency Hunter Badge — Section B2)

Full end-to-end breakdown for the critical path at p99:

| Hop | Mechanism | Latency budget | Justification |
|---|---|---|---|
| External client → Kong gateway | TLS 1.3 handshake + network | 5ms | Single RTT, pre-warmed TLS session |
| Kong → transaction-ingestion-svc | gRPC (mTLS, LAN) | 5ms | Same cluster network |
| Enrichment (device FP + IP geo, parallel) | External REST APIs, concurrent goroutines | 20ms | Concurrent — max of two calls, not sum |
| Ingestion → Kafka publish | Kafka producer (acks=1) | 2ms | Producer batch flush |
| Kafka → detection consumers (lag at steady state) | Kafka consumer poll | 5ms | Near-zero lag target |
| Rule Engine evaluation (parallel with ML + Graph) | In-memory rule cache | 10ms | No DB hit on hot path |
| Anomaly Detection inference (parallel) | ONNX Runtime + Redis feature fetch | 10ms | Models pre-loaded |
| Graph Analysis real-time lookup (parallel) | Neo4j indexed lookup | 20ms | Index-free adjacency O(1) |
| Detection fan-in → Risk Scoring | Kafka consumer poll | 5ms | Signal correlator wait |
| Risk Scoring computation + explanation | In-memory computation | 3ms | ConfigMap thresholds |
| **Total p99 (detection runs in parallel)** | | **~85ms** | ✅ Under 100ms SLA |

Note: Rule Engine, Anomaly Detection, and Graph Analysis run **in parallel**
after the Kafka publish. The effective detection latency = max(10ms, 10ms, 20ms)
= 20ms, not the sum of all three (50ms). This is the key architectural decision
that makes the 100ms SLA achievable.
