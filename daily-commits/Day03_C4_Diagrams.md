# Day 3 Work Log — C4 Diagrams, SLAs, and Persistence

**Date:** 30 June 2026
**Hours logged:** ~8h
**Commit tag:** `Day03_C4_Diagrams`

## What I did
- Finalised C4 Level 2 Container diagram with explicit sync (gRPC) vs async (Kafka) labelling per hop.
- Resolved the Day 2 open question on sync-vs-async for the critical path: both, in sequence — Kafka fan-out to parallel detection engines, gRPC fan-in at Risk Scoring.
- Produced C4 Level 3 Component diagrams for all 4 core services (Transaction Ingestion, Rule Engine, Anomaly Detection, Risk Scoring).
- Built the full Service SLA table across Tiers 1, 2, and 3, with fallback behaviours for each service.
- Wrote polyglot persistence justification document explaining why each store was chosen for its service's access pattern.

## Key decisions made
1. **Critical path latency budget resolved at ~95ms p99** — under the 100ms SLA from Section A1.4, with the parallel detection fan-out (rule/ML/graph run simultaneously, not sequentially) being the key design move that makes this possible.
2. **Signal Correlator timeout set at 80ms** — leaves 15ms buffer for Risk Scoring computation. If Graph Analysis doesn't respond in time, scoring proceeds with Rule + ML only, score adjusted upward by configurable safety margin.
3. **Audit store uses Kafka infinite retention** rather than a mutable database — directly informed by Wirecard case (Part C4); tamper-proofing must be structural, not policy-based.
4. **Enrichment calls run concurrently** in Transaction Ingestion (Go goroutines) — sequential calls to ThreatMetrix then MaxMind would add ~40ms; concurrent cuts it to ~20ms (the slower of the two).

## Open questions / things to revisit
- Exact SHAP computation latency needs benchmarking — assumed <5ms inline for p99, but if this proves too slow in practice, SHAP could be computed asynchronously and attached to the audit record rather than the real-time decision.

## Tomorrow's plan (Day 4)
- Design the complete Kafka topic topology (8+ topics) with partition counts, retention, key schemas, consumer groups.
- Define Protobuf schemas for all event types.
- Configure Schema Registry with compatibility levels.
- Design DLQ topology for poison message handling.
