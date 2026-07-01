# Polyglot Persistence Justification

**Day 3 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 30 June 2026

> "Polyglot persistence" = different data stores for different services, chosen
> for the access pattern of that service rather than a one-size-fits-all default.
> Each choice below is justified by the specific read/write/query needs of its service.

---

## Store choices and justifications

| Service | Data Store | Why this store, not PostgreSQL |
|---|---|---|
| transaction-ingestion-svc | PostgreSQL | ACID transactions for short-lived staging records. Standard relational model suits structured transaction schema. This IS PostgreSQL — it's the default for transactional data. |
| rule-engine-svc | PostgreSQL (rules) + Redis (cache) | Rules stored durably in PostgreSQL. Compiled rules cached in Redis for sub-millisecond in-memory reads on the hot path — a DB query per transaction would blow the 50ms latency budget. |
| anomaly-detection-svc | Redis/Feast (feature store) | Feature retrieval must complete in <1ms. Redis is an in-memory key-value store — far faster than any disk-backed DB for this pattern. Feast adds feature versioning and point-in-time correctness for training/serving consistency. |
| graph-analysis-svc | Neo4j | Relationship traversal (shortest path, community detection, centrality) on a relational DB requires expensive recursive JOIN queries that don't scale beyond a few hops. Neo4j's native graph storage uses index-free adjacency — O(1) per relationship traversal regardless of graph size. No relational alternative can match this for the fraud-ring detection use case. |
| risk-scoring-svc | PostgreSQL | Risk decisions and explanations are structured, need ACID guarantees (a decision must never be half-written), and are queried by case management via standard joins. PostgreSQL is the right fit. |
| case-management-svc | PostgreSQL | Case workflow data (assignments, notes, decisions) is relational, transactional, and relatively low volume. PostgreSQL handles this easily. |
| notification-svc | PostgreSQL | Delivery status tracking is structured and low volume. PostgreSQL is sufficient. |
| audit-compliance-svc | Kafka (infinite retention) | A regular database table can be UPDATE'd or DELETE'd by an admin. Kafka topics with infinite retention and ACL-controlled immutable writes cannot be modified after the fact — this is a structural tamper-proof guarantee, not a configuration setting. (Alternative: Amazon QLDB ledger for same property.) This is the direct lesson from the Wirecard case (Part C4). |
| customer-profile-svc | Cassandra / TimescaleDB | Customer profiles are updated incrementally with every transaction — extremely high write throughput. Cassandra handles high-write, time-ordered workloads efficiently with its LSM-tree storage engine and time-based partitioning. TimescaleDB (PostgreSQL extension) is an alternative if SQL query compatibility is preferred. |
| reference-data-svc | PostgreSQL + Redis cache | Reference data (MCCs, BIN ranges, country risk scores, watchlists) changes rarely but is read millions of times/day. PostgreSQL is the durable source of truth; Redis cache serves the hot reads at sub-millisecond speed. Cache invalidated on any update to the PostgreSQL source. |

## The one rule that overrides everything else

**No two services share a database.**

This is non-negotiable in microservices architecture (Section A1.2: "communication
between bounded contexts is through published interfaces, never through shared
databases"). If two services share a database, they are secretly coupled — a schema
change for one breaks the other, and they can't be deployed or scaled independently.
Every service in this architecture has its own dedicated datastore instance.

## Cross-cutting storage concerns

| Concern | Approach |
|---|---|
| PAN storage | Never stored raw anywhere — tokenised at ingestion using RBI-mandated tokenisation. Only token + card_hash stored. |
| Encryption at rest | AES-256 for all PostgreSQL, Redis, and Cassandra instances (PCI DSS requirement, Day 10). |
| Backup strategy | PostgreSQL: continuous WAL archiving + daily snapshots. Neo4j: daily full backup to cold storage. Kafka: replication factor 3 within region; MirrorMaker 2 for cross-region. |
| Data retention | PostgreSQL transaction data: 7 years (RBI requirement). Audit ledger: infinite retention (Kafka). Customer PII: pseudonymised after retention period expires (GDPR right to erasure vs. RBI 7-year conflict handled by jurisdiction-based config). |
