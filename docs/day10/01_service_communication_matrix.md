# Service Communication Matrix

**Day 10 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 8 July 2026

> This matrix defines which service is allowed to call which other service,
> and by what mechanism. Any connection not listed here is DENIED by the
> Istio AuthorizationPolicy default-deny rule.
> This is the definitive reference for the Istio AuthorizationPolicies in
> configs/istio/authorization_policies.yaml.

## Communication Matrix

| From \ To | api-gateway | txn-ingestion | rule-engine | anomaly-detection | graph-analysis | risk-scoring | case-mgmt | notification | audit | customer-profile | reference-data |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **External Client** | ✅ REST/TLS | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ |
| **api-gateway** | — | ✅ gRPC | ✅ REST (rules mgmt) | ❌ | ❌ | ✅ REST (risk score GET) | ✅ REST | ❌ | ✅ REST (audit query) | ❌ | ❌ |
| **txn-ingestion** | ❌ | — | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Kafka | ❌ | ❌ |
| **rule-engine** | ❌ | ❌ | — | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Kafka | ❌ | ✅ gRPC |
| **anomaly-detection** | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | ❌ | ✅ Kafka | ✅ gRPC | ❌ |
| **graph-analysis** | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ | ❌ | ✅ Kafka | ❌ | ✅ gRPC |
| **risk-scoring** | ❌ | ❌ | ❌ | ❌ | ❌ | — | ❌ | ✅ Kafka | ✅ Kafka | ❌ | ❌ |
| **case-mgmt** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | — | ✅ Kafka | ✅ Kafka | ❌ | ❌ |
| **notification** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | — | ✅ Kafka | ❌ | ❌ |
| **audit** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | — | ❌ | ❌ |
| **customer-profile** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ✅ Kafka | — | ❌ |
| **reference-data** | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | ❌ | — |

✅ = allowed | ❌ = denied at Istio policy level | Kafka = async via topic

## Key security boundaries enforced

| Boundary | Why it matters |
|---|---|
| notification-svc cannot call rule-engine-svc | Explicitly stated in Section A3.1. Notification has no fraud-detection business logic — if compromised, it cannot access or influence detection. |
| audit-compliance-svc has NO outbound calls | Audit only receives (via Kafka). A compromised audit service cannot call any other service to tamper with data before logging it. |
| External clients can only reach api-gateway | No service is directly internet-accessible. All traffic enters through the single gateway where auth, rate limiting, and TLS termination happen. |
| reference-data-svc has no inbound from external | Reference data (MCCs, BIN ranges, watchlists) is sensitive — only rule-engine and graph-analysis can read it via gRPC, never via the public API. |
