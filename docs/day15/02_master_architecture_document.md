# Master Architecture Document
# ShieldPay Real-Time Fraud Detection Platform

**Author:** Aditi Sharma
**Date:** 14 July 2026
**Version:** 1.0 — Final Submission
**Project:** SWE-2C Real-Time Fraud Detection Microservices Architecture

---

## Table of Contents

1. [Executive Summary](#1-executive-summary)
2. [Problem Statement — Legacy Monolith Analysis](#2-problem-statement)
3. [Architecture Overview — Bounded Contexts & Services](#3-architecture-overview)
4. [Communication Architecture](#4-communication-architecture)
5. [Fraud Detection Strategy](#5-fraud-detection-strategy)
6. [Resilience & Security](#6-resilience--security)
7. [Observability](#7-observability)
8. [Deployment & Operations](#8-deployment--operations)
9. [Regulatory Compliance](#9-regulatory-compliance)
10. [Cross-Reference Index](#10-cross-reference-index)

---

## 1. Executive Summary

ShieldPay Financial Services processes 2.4 million transactions per day and
experienced a 340% surge in fraud attempts in Q3 2025, driven by three
concurrent threats: AI-generated synthetic identities, a third-party data
breach exposing 12 million card numbers, and exploitation of the legacy
system's 15-minute batch scoring window.

This architecture decomposes the legacy 1.2-million-line Java monolith into
10 independently deployable microservices organised around domain-driven bounded
contexts. The new platform detects fraud in real time using three complementary
detection layers:

- **Rule Engine** — deterministic evaluation of 500+ configurable rules
  (zero code deployments for rule changes)
- **ML Anomaly Detection** — XGBoost + Isolation Forest + LSTM ensemble
  with real-time feature store and champion-challenger framework
- **Graph Analysis** — Neo4j property graph for fraud ring detection using
  community detection, centrality analysis, and topology matching

All three signals converge in the Risk Scoring service to produce a composite
score (0-1000) with a human-readable explanation for every decision, satisfying
PCI DSS, RBI, and GDPR regulatory requirements simultaneously.

**Key metrics achieved by this architecture:**

| Metric | Target | Design achieves |
|---|---|---|
| Pipeline latency p99 | < 200ms | ~85ms (parallel detection fan-out) |
| Fraud detection rate | > 95% | Three-layer detection; graph catches ring fraud invisible to rules/ML |
| False positive rate | < 0.5% | Rule simulation gate (FP >1% blocks activation); ML champion-challenger |
| System availability | 99.99% (critical path) | Multi-AZ Kubernetes + multi-region DR (Mumbai primary, Singapore secondary) |
| Rule change deployment | Minutes (no code deploy) | YAML-driven rule engine with management UI |
| ML model update | Hours (canary deployment) | 5% canary on live traffic; automated champion-challenger |

---

## 2. Problem Statement — Legacy Monolith Analysis

**Full analysis:** [`docs/day01/02_monolith_analysis.md`](../day01/02_monolith_analysis.md)

### Root Causes of Q3 2025 Crisis

| Pain Point | Business Impact | Architectural Fix |
|---|---|---|
| Single Oracle database bottleneck | 3s analytical queries; single point of failure | Decentralised data ownership — each service owns its datastore |
| 15-minute batch ML scoring | Fraudsters exploited the scoring gap | Real-time streaming inference (Kafka Streams + ONNX Runtime) |
| 500+ rules hardcoded in Java switch statements | Rule changes require 4-hour deployment window | External YAML rule engine with management UI (Day 7) |
| No graph relationship analysis | Synthetic identity rings undetected | New Neo4j graph analysis capability (Day 9) |
| Manual weekly deployments | 4-hour maintenance window; urgent fixes delayed | CI/CD per service; blue-green/canary with automated rollback (Day 14) |
| No fraud ring detection | Organised fraud invisible to individual transaction analysis | Graph community detection, topology matching (Day 9) |

---

## 3. Architecture Overview — Bounded Contexts & Services

**Full decomposition:** [`docs/day02/01_bounded_context_map.md`](../day02/01_bounded_context_map.md)
**Service table:** [`docs/day02/02_service_decomposition_table.md`](../day02/02_service_decomposition_table.md)
**C4 Level 1:** [`diagrams/c4/day02_c4_level1_system_context.md`](../../diagrams/c4/day02_c4_level1_system_context.md)
**C4 Level 2:** [`diagrams/c4/day03_c4_level2_final.md`](../../diagrams/c4/day03_c4_level2_final.md)
**C4 Level 3:** [`diagrams/c4/day03_c4_level3_components.md`](../../diagrams/c4/day03_c4_level3_components.md)

### 10 Microservices

| # | Service | Language | Database | Team |
|---|---|---|---|---|
| 1 | transaction-ingestion-svc | Go | PostgreSQL | Payments Platform |
| 2 | rule-engine-svc | Java | PostgreSQL + Redis | Fraud Rules |
| 3 | anomaly-detection-svc | Python/FastAPI | Redis/Feast | ML Platform |
| 4 | graph-analysis-svc | Java | Neo4j | Graph/Risk Intelligence |
| 5 | risk-scoring-svc | Go | PostgreSQL | Fraud Rules |
| 6 | case-management-svc | Java/Spring | PostgreSQL | Fraud Operations |
| 7 | notification-svc | Node.js | PostgreSQL | Platform Infra |
| 8 | audit-compliance-svc | Go | Kafka ∞ retention | Compliance Engineering |
| 9 | customer-profile-svc | Python | Cassandra | ML Platform |
| 10 | reference-data-svc | Go | PostgreSQL + Redis | Platform Infra |

### Context Mapping Patterns

| Pattern | Applied between |
|---|---|
| Customer-Supplier | Transaction Ingestion → Rule Engine / Anomaly Detection / Graph Analysis → Risk Scoring |
| Conformist | Notification conforms to Risk Scoring and Case Management event schemas |
| Shared Kernel | transaction_id, risk enums shared between Ingestion and Risk Scoring |
| Anti-Corruption Layer | Transaction Ingestion ↔ Legacy Monolith (migration period only) |

---

## 4. Communication Architecture

**Kafka topology:** [`docs/day04/01_kafka_topic_topology.md`](../day04/01_kafka_topic_topology.md)
**Event schemas:** [`configs/kafka_event_schemas.proto`](../../configs/kafka_event_schemas.proto)
**OpenAPI spec:** [`api-specs/openapi.yaml`](../../api-specs/openapi.yaml)
**gRPC services:** [`api-specs/fraud_grpc_services.proto`](../../api-specs/fraud_grpc_services.proto)
**Event Storming:** [`diagrams/event-storming/day06_full_event_storm.md`](../../diagrams/event-storming/day06_full_event_storm.md)
**Sagas:** [`docs/day06/01_saga_orchestration.md`](../day06/01_saga_orchestration.md)

### Communication Patterns Summary

| Path | Mechanism | Why |
|---|---|---|
| External → Platform | REST/TLS via Kong API Gateway | Ubiquity; gateway handles auth, rate limiting, TLS termination |
| Transaction Ingestion → Detection engines | Kafka async fan-out | Decoupling; detection engines can fail without blocking ingestion |
| Detection results → Risk Scoring | Kafka fan-in with Signal Correlator | Parallel detection; correlator waits up to 80ms for all 3 signals |
| Service → Service (internal) | gRPC with mTLS (Istio) | Binary serialisation; HTTP/2 multiplexing; strongly-typed contracts |
| All services → Audit | Kafka publish only (one-way) | Tamper isolation; audit never calls back |

### 10 Kafka Topics

| Topic | Key | Retention | Purpose |
|---|---|---|---|
| fraud.transactions.raw | card_number_hash | 30 days | Raw inbound transactions |
| fraud.transactions.enriched | card_number_hash | 30 days | Enriched — fan-out to 3 detection engines |
| fraud.rule.results | transaction_id | 7 days | Rule engine outputs |
| fraud.anomaly.scores | transaction_id | 7 days | ML model scores + SHAP values |
| fraud.graph.signals | transaction_id | 7 days | Graph relationship signals |
| fraud.risk.decisions | transaction_id | 90 days | Final composite decisions |
| fraud.alerts | card_number_hash | 30 days | High-risk alerts for notification |
| notifications.outbound | customer_id_hash | 7 days | Notification delivery requests |
| fraud.audit.events | trace_id | **Infinite** | Immutable Merkle-chained audit log |
| graph.updates | entity_id | 7 days | Graph node/edge updates |

### 3 Saga Workflows

| Saga | Trigger | Steps | Compensating actions |
|---|---|---|---|
| Transaction Processing | TransactionSubmitted | Enrich → Parallel detection → Risk Score → Notify | Partial enrichment fallback; signal timeout fallback; score safety margin |
| Fraud Investigation | TransactionFlaggedForReview | Create Case → Assign → Investigate → Decide | Unfreeze card on false positive; cancel case if assignment fails |
| Card Blocking | FraudConfirmed | Block card → Issue replacement → Notify cardholder → Update profile | Dual-authorisation reversal only (no automatic compensation) |

---

## 5. Fraud Detection Strategy

**Rule engine:** [`docs/day07/01_rule_lifecycle_and_simulation.md`](../day07/01_rule_lifecycle_and_simulation.md)
**Rule schema:** [`configs/rule_engine_schema.yaml`](../../configs/rule_engine_schema.yaml)
**Sample rules:** [`configs/sample_rules.yaml`](../../configs/sample_rules.yaml)
**ML architecture:** [`docs/day08/01_ml_serving_architecture.md`](../day08/01_ml_serving_architecture.md)
**Graph schema:** [`docs/day09/01_graph_schema.md`](../day09/01_graph_schema.md)
**Cypher queries:** [`docs/day09/02_cypher_queries.md`](../day09/02_cypher_queries.md)

### Three-Layer Detection

```
Transaction
    │
    ├─── Rule Engine ──────── 20+ rule categories
    │    deterministic        velocity, amount, geo, MCC,
    │    configurable         watchlist, behavioural, device
    │    <50ms p99
    │
    ├─── Anomaly Detection ── XGBoost (50%) + Isolation Forest (30%) + LSTM (20%)
    │    ML-based             10% base sampling; 100% for slow/error/fraud
    │    unknown patterns     real-time feature store (Redis/Feast)
    │    <30ms p99            champion-challenger framework
    │
    └─── Graph Analysis ───── 9 node types, 10 relationship types
         relationship-based   Community detection (Louvain)
         fraud rings          Centrality (PageRank)
         <50ms p99            Path analysis (shortest path to known fraud)
                              3 topology templates
    │
    ▼
Risk Scoring
    w1×RuleScore + w2×MLScore + w3×GraphScore
    0-1000 composite score
    Configurable thresholds per market/channel/product
    SHAP explainability — top 5 contributing features
    │
    ├── 0-199:   AUTO_APPROVE  (<100ms)
    ├── 200-599: STEP_UP_AUTH  (<5s)
    ├── 600-799: MANUAL_REVIEW (<4 hours)
    └── 800-999: AUTO_DECLINE  (<100ms)
```

### Rule Engine Safeguards

| Gate | Threshold | Effect |
|---|---|---|
| JSON Schema validation | At save time | Malformed rules blocked before reaching rule store |
| 30-day simulation | FP rate > 1% | Blocks activation — never reaches production |
| A/B shadow testing | 7-day minimum | New version must match champion on all metrics before promotion |
| Performance monitoring | p99 > max_evaluation_time_ms | P2 alert; rule auto-deprecated |

### ML Model Safeguards

| Gate | Threshold | Effect |
|---|---|---|
| Holdout validation | AUC ≥ 0.95, FP ≤ 0.5% | Must pass before staging deployment |
| 5% canary on live traffic | 7-day shadow | Challenger must match champion on AUC, recall, FP rate, latency |
| PSI drift monitoring | PSI > 0.25 | P2 alert; triggers retraining pipeline |
| Chargeback reconciliation | Recall < 90% | P2 alert; triggers retraining |

---

## 6. Resilience & Security

**Service mesh:** [`configs/istio/`](../../configs/istio/)
**Communication matrix:** [`docs/day10/01_service_communication_matrix.md`](../day10/01_service_communication_matrix.md)
**Encryption strategy:** [`docs/day10/02_encryption_strategy.md`](../day10/02_encryption_strategy.md)
**PCI DSS mapping:** [`docs/day10/03_pci_dss_compliance_mapping.md`](../day10/03_pci_dss_compliance_mapping.md)
**API gateway:** [`docs/day11/01_api_gateway_config.md`](../day11/01_api_gateway_config.md)
**Rate limiting:** [`docs/day11/02_rate_limiting_policy.md`](../day11/02_rate_limiting_policy.md)

### Security Architecture Summary

| Layer | Mechanism | Satisfies |
|---|---|---|
| Perimeter | Kong API Gateway: TLS 1.3, JWT RS256, 5-tier rate limiting | PCI DSS Req 1, 8 |
| Service-to-service | Istio mTLS STRICT (zero exceptions) | PCI DSS Req 4.2.1 |
| Authorisation | Default-deny AuthorizationPolicy + per-service allows | PCI DSS Req 7 |
| Data at rest | AES-256 all stores; HashiCorp Vault key rotation every 90 days | PCI DSS Req 3.5 |
| PAN protection | Tokenised at entry; only card_number_hash stored anywhere | RBI Tokenisation Mandate Oct 2022 |
| Audit trail | Merkle-chained AuditEvents on Kafka ∞ retention topic | PCI DSS Req 10, Wirecard lesson |

### Fallback Strategies (Netflix-style Resilience)

| Service unavailable | Fallback | Impact |
|---|---|---|
| anomaly-detection-svc | Rule + Graph only; approval threshold -20% | Slightly more conservative |
| graph-analysis-svc | Rule + ML only; score +100 safety margin | May miss fraud ring signals |
| customer-profile-svc | Population-average features | ML less personalised |
| reference-data-svc | Last Redis-cached values (max 5 min staleness) | Rules use slightly stale BIN/MCC data |
| notification-svc | Kafka queue; delivered on recovery | Notification delay, no decision impact |

---

## 7. Observability

**Prometheus rules:** [`configs/monitoring/prometheus_rules.yaml`](../../configs/monitoring/prometheus_rules.yaml)
**Grafana dashboards:** [`docs/day12/01_grafana_dashboards.md`](../day12/01_grafana_dashboards.md)
**Runbooks:** [`docs/day12/02_runbooks.md`](../day12/02_runbooks.md)
**Logging standard:** [`configs/observability/logging_standard.md`](../../configs/observability/logging_standard.md)
**Tracing config:** [`configs/observability/tracing_config.yaml`](../../configs/observability/tracing_config.yaml)
**SLA specification:** [`docs/day13/01_sla_specification.md`](../day13/01_sla_specification.md)

### Three Pillars of Observability

| Pillar | Tool | Key design decision |
|---|---|---|
| Metrics | Prometheus + Grafana | Recording rules pre-compute all dashboard queries; 4 dashboards by audience |
| Logs | Fluent Bit → Elasticsearch → Kibana | Mandatory JSON fields; PII masking at library level; 7-year cold retention |
| Traces | OpenTelemetry → Jaeger | trace_id propagated across gRPC AND Kafka; 10% base + 100% for slow/error/fraud |

### Alert Severity Matrix

| Severity | Routing | Examples |
|---|---|---|
| P1 — Critical | PagerDuty + auto-escalate 5min | Pipeline down, detection collapsed, latency >200ms sustained |
| P2 — High | Slack #alerts + escalate 30min | Service error rate >1%, Kafka lag >10k, model drift PSI >0.25 |
| P3 — Medium | Daily digest email | FP rate +20% over baseline, non-critical service degraded |
| P4 — Low | Weekly review dashboard | Infra cost spike |

---

## 8. Deployment & Operations

**CI/CD pipeline:** [`docs/day14/01_cicd_pipeline.md`](../day14/01_cicd_pipeline.md)
**DR plan:** [`docs/day14/02_dr_plan.md`](../day14/02_dr_plan.md)
**Dockerfiles:** [`samples/dockerfiles/`](../../samples/dockerfiles/)
**Kubernetes manifests:** [`samples/k8s/`](../../samples/k8s/)

### Deployment Strategy Per Service

| Service | Strategy | Reason |
|---|---|---|
| rule-engine-svc | Blue-Green | Rules must switch atomically — no partial rule sets |
| anomaly-detection-svc | Canary (5%→100%) | ML models need live traffic signal before full promotion |
| audit-compliance-svc | Blue-Green | Audit schema changes must be atomic |
| All others | Rolling update | Stateless; readiness probes ensure zero message loss |
| DB schema migrations | Expand-Contract | Never break currently deployed pods |

### Disaster Recovery

| Tier | Services | RPO | RTO | Mechanism |
|---|---|---|---|---|
| 1 — Critical | Ingestion, Rule Engine, ML, Risk Scoring | < 1 min | < 5 min | Automated Route 53 failover; pre-provisioned Singapore standby |
| 2 — Supporting | Case Management, Notification, Analytics | < 15 min | < 30 min | Semi-automated failover |
| 3 — Non-critical | Reporting, Admin tools | < 1 hour | < 4 hours | Manual restore from backup |

---

## 9. Regulatory Compliance

**Full mapping:** [`docs/day10/03_pci_dss_compliance_mapping.md`](../day10/03_pci_dss_compliance_mapping.md)

| Framework | Key requirements | How satisfied |
|---|---|---|
| **PCI DSS v4.0** | Encrypt cardholder data; network segmentation; audit logging | AES-256 at rest; mTLS in transit; Istio NetworkPolicy; Merkle-chained audit |
| **RBI Guidelines** | Real-time monitoring; AFA; tokenisation; 7-year retention; STR filing | Entire real-time pipeline; OTP step-up auth; tokenisation at ingestion; Kafka ∞ retention; audit-compliance-svc STR endpoint |
| **GDPR** | Data minimisation; right to erasure; purpose limitation | card_number_hash only (no raw PAN); pseudonymisation after retention period; legitimate interest basis |
| **RBI vs GDPR conflict** | RBI: 7-year retention; GDPR: right to erasure | Resolved by jurisdiction-based ConfigMap — Indian cardholders get RBI policy; EU cardholders get pseudonymisation after GDPR period |

---

## 10. Cross-Reference Index

| Topic | Primary document | Related documents |
|---|---|---|
| Service boundaries | `docs/day02/01_bounded_context_map.md` | `docs/day01/02_monolith_analysis.md` |
| Architecture diagrams | `diagrams/c4/day03_c4_level2_final.md` | `diagrams/c4/day02_c4_level1_system_context.md`, `diagrams/c4/day03_c4_level3_components.md` |
| Kafka topics | `docs/day04/01_kafka_topic_topology.md` | `configs/kafka_event_schemas.proto` |
| API contracts | `api-specs/openapi.yaml` | `api-specs/fraud_grpc_services.proto`, `docs/day05/01_api_gateway_routing.md` |
| Event architecture | `diagrams/event-storming/day06_full_event_storm.md` | `docs/day06/01_saga_orchestration.md` |
| Rule engine | `configs/rule_engine_schema.yaml` | `configs/sample_rules.yaml`, `docs/day07/01_rule_lifecycle_and_simulation.md` |
| ML architecture | `docs/day08/01_ml_serving_architecture.md` | `configs/kafka_event_schemas.proto` (AnomalyScore message) |
| Graph analysis | `docs/day09/01_graph_schema.md` | `docs/day09/02_cypher_queries.md`, `docs/day09/03_graph_sync_and_maintenance.md` |
| Security | `configs/istio/authorization_policies.yaml` | `docs/day10/01_service_communication_matrix.md`, `docs/day10/02_encryption_strategy.md` |
| Compliance | `docs/day10/03_pci_dss_compliance_mapping.md` | `configs/istio/peer_authentication.yaml` |
| API gateway | `docs/day11/01_api_gateway_config.md` | `docs/day11/02_rate_limiting_policy.md`, `docs/day11/03_auth_flow_diagrams.md` |
| Monitoring | `configs/monitoring/prometheus_rules.yaml` | `docs/day12/01_grafana_dashboards.md`, `docs/day12/02_runbooks.md` |
| Observability | `configs/observability/tracing_config.yaml` | `configs/observability/logging_standard.md`, `docs/day13/01_sla_specification.md` |
| CI/CD | `docs/day14/01_cicd_pipeline.md` | `samples/dockerfiles/`, `samples/k8s/` |
| Disaster recovery | `docs/day14/02_dr_plan.md` | `docs/day13/01_sla_specification.md` |
| Error detection | `docs/day15/01_error_detection.md` | — |
