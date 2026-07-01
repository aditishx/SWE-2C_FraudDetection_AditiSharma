# C4 Level 2 — Container Diagram (DRAFT — finalized on Day 3)

**Day 2 Deliverable | SWE-2C Fraud Detection Microservices Architecture**

> **Status: Draft.** This shows all containers (services, databases, broker) and a
> first pass at communication style. Day 3 will finalise this with explicit
> synchronous (gRPC, solid arrow) vs. asynchronous (Kafka, dashed arrow) labelling
> per hop, plus the API gateway and service mesh layer.

## Diagram (draft)

```mermaid
flowchart TB
    GW["API Gateway"]
    KAFKA{{"Apache Kafka<br/>(event backbone)"}}

    TI["transaction-ingestion-svc"]
    RE["rule-engine-svc"]
    AD["anomaly-detection-svc"]
    GA["graph-analysis-svc"]
    RS["risk-scoring-svc"]
    CM["case-management-svc"]
    NO["notification-svc"]
    AC["audit-compliance-svc"]
    CP["customer-profile-svc"]
    RD["reference-data-svc"]

    PG_TI[(PostgreSQL)]
    PG_RE[(PostgreSQL + Redis)]
    REDIS_AD[(Redis/Feast)]
    NEO[(Neo4j)]
    PG_RS[(PostgreSQL)]
    PG_CM[(PostgreSQL)]
    PG_NO[(PostgreSQL)]
    LEDGER[(Kafka infinite-retention / QLDB)]
    CASS[(Cassandra/TimescaleDB)]
    PG_RD[(PostgreSQL + Redis)]

    GW --> TI
    GW --> CM
    GW --> RE

    TI --> KAFKA
    KAFKA --> RE
    KAFKA --> AD
    KAFKA --> GA
    RE --> KAFKA
    AD --> KAFKA
    GA --> KAFKA
    KAFKA --> RS
    RS --> KAFKA
    KAFKA --> CM
    KAFKA --> NO
    KAFKA --> AC

    TI --- PG_TI
    RE --- PG_RE
    AD --- REDIS_AD
    GA --- NEO
    RS --- PG_RS
    CM --- PG_CM
    NO --- PG_NO
    AC --- LEDGER
    CP --- CASS
    RD --- PG_RD

    AD -.->|reads via API| CP
    RE -.->|reads via API| RD
    GA -.->|reads via API| RD

    classDef svc fill:#B5D4F4,stroke:#185FA5,color:#042C53
    classDef infra fill:#CECBF6,stroke:#534AB7,color:#26215C
    classDef audit fill:#FAC775,stroke:#854F0B,color:#412402
    classDef db fill:#E8E8E8,stroke:#888888,color:#333333

    class TI,RE,AD,GA,RS,CM,NO,CP,RD svc
    class AC audit
    class GW,KAFKA infra
    class PG_TI,PG_RE,REDIS_AD,NEO,PG_RS,PG_CM,PG_NO,LEDGER,CASS,PG_RD db
```

## What's confirmed vs. still open

**Confirmed today:**
- All 10 service containers
- Each service's dedicated data store (polyglot persistence — no shared databases)
- Kafka as the central event backbone connecting Ingestion → Detection engines → Risk Scoring → downstream consumers
- API Gateway as the single external entry point

**Deliberately left open for Day 3:**
- Exact gRPC method names for synchronous calls (e.g., `RuleEngine.Evaluate`)
- Exact Kafka topic names for each arrow (formalised properly on Day 4, previewed structurally here)
- Service mesh sidecars (Day 10)
- Per-service SLA table (Day 3)

**Our resolution (to be finalised Day 3):** Transaction Ingestion publishes the
enriched transaction to Kafka *and* the critical-path services consume it as a
low-latency streaming read (not a slow batch poll) — Kafka consumer lag for this
path must stay near-zero. This keeps the architecture event-driven and decoupled
(any one detection engine can be down without crashing ingestion) while still
meeting the latency SLA, because a healthy Kafka consumer reads new messages within
single-digit milliseconds. We will document the precise latency trade-off with
numbers on Day 3, since "Latency Hunter" badge criteria (Section B2) require
mathematical justification per hop.
