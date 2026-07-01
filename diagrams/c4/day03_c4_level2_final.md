# C4 Level 2 — Container Diagram (FINAL)

**Day 3 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 30 June 2026

> Supersedes the draft produced on Day 2. This version finalises:
> - Synchronous gRPC calls (solid arrows, labelled with RPC method name)
> - Asynchronous Kafka events (dashed arrows, labelled with topic name)
> - API Gateway and service mesh layer
> - Per-hop latency budget annotations on the critical path

## Critical path latency decision (open question resolved from Day 2)

Day 2 left open whether Transaction Ingestion → detection engines is sync (gRPC)
or async (Kafka). Resolution:

**The critical path uses BOTH, in sequence:**

1. Transaction Ingestion publishes to `fraud.transactions.enriched` (Kafka) — this
   is the fan-out to Rule Engine, Anomaly Detection, and Graph Analysis in parallel.
2. Each detection engine reads from that topic with a **dedicated low-latency consumer
   group** (lag target: <5ms at steady state — see SLA table).
3. Each engine publishes its result to its own topic.
4. Risk Scoring aggregates the three result topics synchronously via gRPC
   (`RiskScoringService.ComputeScore`) — because it needs all three signals *before*
   it can emit a decision, making this a blocking fan-in.

**Latency budget breakdown (critical path, p99):**

| Hop | Mechanism | Budget |
|---|---|---|
| Channel → API Gateway | TLS/REST | 5ms |
| API Gateway → Transaction Ingestion | gRPC | 5ms |
| Ingestion enrichment (device FP, IP geo) | External REST calls | 20ms |
| Ingestion → Kafka publish | Kafka producer | 2ms |
| Kafka → Rule Engine consumer | Kafka consumer lag | 5ms |
| Rule Engine evaluation | In-memory rule cache | 10ms |
| Kafka → Anomaly Detection consumer | Kafka consumer lag | 5ms |
| Anomaly Detection inference | ONNX/feature store | 10ms |
| Kafka → Graph Analysis consumer | Kafka consumer lag | 5ms |
| Graph Analysis lookup (real-time path only) | Neo4j indexed lookup | 20ms |
| All 3 results → Risk Scoring (gRPC) | gRPC fan-in | 5ms |
| Risk Scoring computation + explanation | In-memory | 3ms |
| **Total p99 critical path** | | **~95ms ✅ < 100ms SLA** |

Note: Rule Engine, Anomaly Detection, and Graph Analysis run **in parallel** after
the Kafka publish — they don't add latency sequentially. The longest of the three
(Graph Analysis at ~30ms) is the effective bottleneck for the parallel batch, not
the sum of all three.

## Diagram

```mermaid
flowchart TB
    EXT["External Channels\n(POS / E-com / UPI / ATM)"]
    GW["API Gateway\n(Kong / AWS API GW)"]
    MESH["Service Mesh\n(Istio/Envoy sidecars)"]

    subgraph KAFKA_TOPICS["Apache Kafka — Event Backbone"]
        T1("fraud.transactions.raw")
        T2("fraud.transactions.enriched")
        T3("fraud.rule.results")
        T4("fraud.anomaly.scores")
        T5("fraud.graph.signals")
        T6("fraud.risk.decisions")
        T7("fraud.alerts")
        T8("fraud.audit.events")
        T9("notifications.outbound")
    end

    TI["transaction-ingestion-svc\n(Go)"]
    RE["rule-engine-svc\n(Java)"]
    AD["anomaly-detection-svc\n(Python/FastAPI)"]
    GA["graph-analysis-svc\n(Java)"]
    RS["risk-scoring-svc\n(Go)"]
    CM["case-management-svc\n(Java/Spring)"]
    NO["notification-svc\n(Node.js)"]
    AC["audit-compliance-svc\n(Go)"]
    CP["customer-profile-svc\n(Python)"]
    RD["reference-data-svc\n(Go)"]

    DB_TI[("PostgreSQL\ntransaction staging")]
    DB_RE[("PostgreSQL\nrule definitions")]
    CACHE_RE[("Redis\nrule cache")]
    FEAT_AD[("Redis/Feast\nfeature store")]
    NEO[("Neo4j\nproperty graph")]
    DB_RS[("PostgreSQL\nrisk decisions")]
    DB_CM[("PostgreSQL\ncases")]
    DB_NO[("PostgreSQL\ndelivery status")]
    LEDGER[("Kafka ∞ retention\naudit ledger")]
    CASS[("Cassandra\nbehavioural profiles")]
    DB_RD[("PostgreSQL + Redis\nreference data")]

    EXT -->|"REST/ISO8583"| GW
    GW -->|"gRPC: IngestTransaction"| TI
    GW -->|"REST: GET /cases"| CM
    GW -->|"REST: GET/POST /rules"| RE

    TI -->|"publish"| T1
    T1 -->|"subscribe"| TI
    TI -->|"publish"| T2
    T2 -.->|"subscribe\n[lag <5ms]"| RE
    T2 -.->|"subscribe\n[lag <5ms]"| AD
    T2 -.->|"subscribe\n[lag <5ms]"| GA

    RE -->|"publish"| T3
    AD -->|"publish"| T4
    GA -->|"publish"| T5

    T3 -.->|"subscribe"| RS
    T4 -.->|"subscribe"| RS
    T5 -.->|"subscribe"| RS

    RS -->|"publish"| T6
    RS -->|"publish"| T7
    T6 -.->|"subscribe"| CM
    T7 -.->|"subscribe"| NO
    T7 -.->|"subscribe"| AC
    T6 -.->|"subscribe"| AC
    T3 -.->|"subscribe"| AC
    T4 -.->|"subscribe"| AC

    RS -->|"publish"| T9
    T9 -.->|"subscribe"| NO

    NO -->|"push/SMS/email/webhook"| EXT_NOTIFY["Customer / Merchant\n/ Internal Teams"]

    TI --- DB_TI
    RE --- DB_RE
    RE --- CACHE_RE
    AD --- FEAT_AD
    GA --- NEO
    RS --- DB_RS
    CM --- DB_CM
    NO --- DB_NO
    AC --- LEDGER
    CP --- CASS
    RD --- DB_RD

    AD -->|"gRPC: GetFeatures"| CP
    RE -->|"gRPC: GetReferenceData"| RD
    GA -->|"gRPC: GetReferenceData"| RD

    classDef svc fill:#B5D4F4,stroke:#185FA5,color:#042C53
    classDef infra fill:#CECBF6,stroke:#534AB7,color:#26215C
    classDef audit fill:#FAC775,stroke:#854F0B,color:#412402
    classDef db fill:#E8E8E8,stroke:#888,color:#333

    class TI,RE,AD,GA,RS,CM,NO,CP,RD svc
    class AC audit
    class GW,MESH infra
    class DB_TI,DB_RE,CACHE_RE,FEAT_AD,NEO,DB_RS,DB_CM,DB_NO,LEDGER,CASS,DB_RD db
```
