# Day 2 Work Log — Bounded Context Identification and Service Decomposition

**Date:** 29 June 2026
**Commit tag:** `Day02_Service_Decomposition`

## What I did
- Grouped Day 1's Event Storming clusters into 9 bounded contexts using DDD heuristics (business capability alignment, data ownership, team alignment, change frequency, scalability, failure isolation).
- Added a 10th lightweight service (Reference Data) for shared lookup data, bringing total to 10 services — within the 8-12 target.
- Documented Context Mapping patterns (Customer-Supplier, Conformist, Shared Kernel, Anti-Corruption Layer) between all contexts.
- Produced the C4 Level 1 System Context diagram showing all 6 external system integrations.
- Started the C4 Level 2 Container diagram (draft — all 10 services + their dedicated data stores + Kafka backbone).
- Built the full Service Decomposition Table with tech stack justification, data store choice, and realistic team ownership (5 teams across 10 services).

## Key decisions made
1. **Did NOT merge Rule Engine, Anomaly Detection, and Graph Analysis into one "Detection" service**, even though they're conceptually related — their wildly different scaling/latency/infra profiles (deterministic vs. GPU-serving vs. graph-DB) is exactly the justification Section A1.1 gives for separating them. Merging them would recreate the monolith's coupling problem under a new name.
2. **Audit & Compliance is strictly one-directional** — every service publishes events *to* it, but it never gets called back. This isn't just convenient; it's a security property that protects audit-trail integrity (directly informed by the Wirecard case study we'll formalise on... actually read ahead in Part C4, even though that's a later day's required reading — worth noting early).
3. **Shared team ownership across related services** (Fraud Rules Team owns both Rule Engine + Risk Scoring; ML Platform Team owns both Anomaly Detection + Customer Profile) to keep realistic headcount (~30-40 engineers total) rather than inventing 10 separate teams.
4. **Left the exact sync-vs-async mechanics of the critical path as an open question for Day 3** — flagged explicitly rather than guessing, since the "Latency Hunter" badge (Section B2) requires mathematical justification we don't have yet.

## Open questions / things to revisit
- Need numeric latency budget breakdown per hop before finalising whether Ingestion → Rule Engine is sync (gRPC) or via Kafka — this is Day 3's job.
- Reference Data is currently a "lightweight" 10th service — may reconsider whether it should be a shared library/sidecar cache instead of a full service, once we see real query patterns in Day 7 (rules) and Day 9 (graph).

## Blockers
None.

## Tomorrow's plan (Day 3)
- Finalise C4 Level 2 with explicit sync (gRPC) vs async (Kafka) labelling per hop.
- Produce C4 Level 3 Component diagrams for 4 core services (Transaction Ingestion, Rule Engine, Anomaly Detection, Risk Scoring).
- Define per-service SLA table (latency percentiles, availability, throughput, error budget).
- Write the polyglot persistence justification document.
