# Day 6 Work Log — Event-Driven Architecture Specification

**Date:** 3 July 2026
**Commit tag:** `Day06_EDA_Specification`

## What I did
- Expanded Day 1's 11-event skeleton to 55 domain events across 4 aggregates (Transaction, FraudCase, Card, Notification).
- Added error-path events (EnrichmentTimedOut, RuleEvaluationTimedOut, FeatureStoreMiss, GraphAnalysisTimedOut) — these are as important as happy-path events for production resilience.
- Produced 3 Saga orchestration diagrams with full compensating transaction tables.
- Designed 5 CQRS read models for the Analytics Dashboard with Kafka Streams topology per read model.

## Key decisions made
1. **Orchestration pattern (not choreography) for Fraud Investigation Saga** — the Wirecard case (Part C4) showed that audit completeness in fraud workflows requires an explicit orchestrator that logs every step and its compensating action. Choreography (each service reacts to events independently) is harder to audit and trace when something goes wrong.
2. **`FraudConfirmed` → `CardPermanentlyBlocked` has no compensation** — by design. Once fraud is confirmed by an analyst and permanently blocked, reversing it requires a dual-authorisation audit-logged maintenance operation. This is not an accident; it mirrors real-world card scheme rules.
3. **Error-path events outnumber happy-path events** — 17 of 55 events are error/timeout/fallback events. This is intentional: a system that only models the happy path doesn't tell you what it does when things go wrong, which is exactly what the CRO and Head of Compliance (Section B1.3) will ask.
4. **CQRS read models have different update frequencies** — real-time stats update per event (<1s lag), but ML model performance updates daily (because chargeback confirmation data arrives 30-90 days after the transaction). Forcing the same update frequency on both would either make analytics stale or make ML monitoring needlessly complex.

## Open questions / things to revisit
- `card-management` is referenced as a "logical" service in Sagas 2 and 3 — this is a capability that may either be a new microservice or be owned by the Core Banking System (external). Need to clarify during Day 10 when we map service communication policies.
