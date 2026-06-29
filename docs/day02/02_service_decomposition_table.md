# Service Decomposition Table

**Day 2 Deliverable | SWE-2C Fraud Detection Microservices Architecture**

For each service: bounded context, primary responsibility, language/framework
(justified by the workload), data store, and the team that would realistically own
it (per the "team alignment" heuristic — 3-5 developers each, Section A1.2).

| # | Service Name | Bounded Context | Primary Responsibility | Tech (Language/Framework) | Data Store | Team Ownership |
|---|---|---|---|---|---|---|
| 1 | **transaction-ingestion-svc** | Transaction Ingestion | Receive raw transactions from all channels, normalise format, enrich with device/geo data, publish to Kafka | Go (high-throughput I/O, low memory overhead per request) | PostgreSQL (short-lived transactional staging) | Payments Platform Team |
| 2 | **rule-engine-svc** | Rule Engine | Evaluate transactions against configurable rules, return trigger/pass results within latency budget | Java + a rules library, or Rust for raw speed (deterministic, latency-critical) | PostgreSQL (rule definitions/versions) + Redis (compiled rule cache) | Fraud Rules Team |
| 3 | **anomaly-detection-svc** | Anomaly Detection | Serve ML model predictions in real time; manage feature retrieval | Python (FastAPI) + ONNX Runtime/Triton for serving | Redis/Feast (feature store) + model registry (MLflow) | ML Platform Team |
| 4 | **graph-analysis-svc** | Graph Analysis | Maintain fraud relationship graph; run community detection, centrality, path queries | Java or Python with Neo4j driver | Neo4j (property graph) | Graph/Risk Intelligence Team |
| 5 | **risk-scoring-svc** | Risk Scoring | Aggregate Rule + ML + Graph signals into composite score; apply thresholds; generate explanations | Java or Go (latency-critical orchestration) | PostgreSQL (decisions + explanations) | Fraud Rules Team (shared with #2) |
| 6 | **case-management-svc** | Case Management | Analyst workflow: assignment, investigation tools, decision recording | Java/Spring Boot or Node.js (workflow-heavy, less latency-critical) | PostgreSQL (cases, assignments, notes) | Fraud Operations Team |
| 7 | **notification-svc** | Notification | Multi-channel delivery (SMS/email/push/webhook/Slack/PagerDuty) with localisation & retry | Node.js or Go (I/O-bound, many concurrent outbound calls) | PostgreSQL (delivery status) + template store | Platform Infra Team |
| 8 | **audit-compliance-svc** | Audit & Compliance | Append-only, hash-chained audit logging; regulatory query endpoints | Java/Go, append-only writes only | Kafka (infinite retention topic) or Amazon QLDB-style ledger | Compliance Engineering Team |
| 9 | **customer-profile-svc** | Customer Profile | Maintain behavioural profiles (avg amounts, merchants, geolocations, devices), updated incrementally | Java or Python | Cassandra/TimescaleDB (high write throughput, time-series friendly) | ML Platform Team (shared with #3) |
| 10 | **reference-data-svc** | Reference Data | Serve MCCs, BIN ranges, country risk scores, watchlists — read-heavy lookups | Go (simple, fast reads) | PostgreSQL + Redis cache | Platform Infra Team (shared with #7) |

## Notes on team ownership realism

Per Section B1.3 (VP of Engineering's evaluation lens — "can a team of 30-40 engineers
build and maintain this?"), we've deliberately **shared ownership across a few services**
rather than inventing 10 separate teams:

- **Fraud Rules Team** owns both Rule Engine and Risk Scoring — they're conceptually
  joined at the hip (rule outputs feed directly into scoring) and changing one often
  means changing the other's contract.
- **ML Platform Team** owns both Anomaly Detection and Customer Profile — profile
  features are the primary input to the ML models, so the same team that builds
  features should own the store that produces them.
- **Platform Infra Team** owns Notification and Reference Data — both are
  "horizontal utility" services with no fraud-domain logic of their own.

This gives us **5 real teams of ~6-8 engineers each** (within the 30-40 total
headcount), each owning 1-2 services — satisfying both the "3-5 developers per
service" guidance and overall headcount realism.

## Polyglot persistence — why different databases per service

This previews Day 3's persistence justification, but the short version: each store
was picked for the *access pattern* of its service, not by default —

- **PostgreSQL** where we need ACID transactions and structured queries (Ingestion staging, Rules, Risk decisions, Cases, Audit-adjacent, Reference Data)
- **Redis** wherever sub-millisecond reads matter (rule cache, feature store, reference data cache)
- **Neo4j** is non-negotiable for Graph Analysis — relationship traversal in a relational DB would require expensive recursive joins that don't scale
- **Cassandra/TimescaleDB** for Customer Profile because behavioural data is high-write-throughput and naturally time-partitioned (this transaction, then this transaction, then...)
- **Kafka with infinite retention** (or a ledger DB) for Audit — because the storage engine itself must guarantee append-only, immutable writes; a regular database table can be `UPDATE`d or `DELETE`d by anyone with admin rights, which defeats the entire purpose (see Wirecard case, Part C4)

## Service count check

**10 services total** — within the Section A1.3 target of 8-12. ✅
