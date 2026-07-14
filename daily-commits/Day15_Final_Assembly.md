# Day 15 Work Log — Final Assembly and Review

**Date:** 14 July 2026
**Commit tag:** `Day15_Final_Assembly`

## What I did
- Identified and documented 5 embedded errors in the project brief:
  (1) "Laarnign" typo in Section A2.3 heading,
  (2) "OPENAI" vs "OpenAPI" in Day 5 heading,
  (3) incorrect RBI fraud reporting threshold (₹2 lakh stated vs ₹1 lakh actual),
  (4) latency SLA contradiction between Sections A1.4 and A2.5,
  (5) scoring framework inconsistency between Part B (6 levels) and Part F (7 dimensions).
- Assembled the Master Architecture Document consolidating all 14 days with
  full cross-reference index and navigation links.
- Wrote AI Usage Disclosure per Section E5 requirements.
- Conducted self-review against the 1000-point rubric across all 7 dimensions.
- Verified diagram consistency: service names, data flows, and topic names
  are consistent across C4 diagrams, Event Storming, Saga diagrams, Kafka
  topology, and Istio configurations.

## Self-review against rubric dimensions

| Dimension | Evidence | Confidence |
|---|---|---|
| Problem Understanding | Monolith analysis (Day 1); 5 pain points mapped to architectural fixes | High |
| Solution Quality | 10 services; C4 Level 1/2/3; Kafka topology; Istio config; Dockerfiles; K8s manifests | High |
| Research & Analysis | Netflix (C3), Target (C1), Cosmos Bank (C2), Wirecard (C4) lessons incorporated throughout | High |
| Presentation & Clarity | Master Architecture Document with cross-reference index; consistent diagram naming | High |
| Innovation & Creativity | Adaptive rate limiting; Merkle-chained audit events; dual-tier feature store; jurisdiction-based GDPR/RBI resolution | High |
| Feasibility & Practicality | 5 teams of 6-8 engineers; realistic HPA settings; per-hop latency budget; error budget policy | High |
| CV Alignment | [Aditi to personalise based on her background and stated CV alignment] | — |

## Diagram consistency check

- Service names: consistent across C4 Level 2, Kafka topology, Istio configs,
  Kubernetes manifests, communication matrix ✅
- Kafka topic names: consistent across topic topology doc, Protobuf schemas,
  Prometheus recording rules, Saga diagrams ✅
- Latency budgets: Day 3 per-hop breakdown (85ms) consistent with Day 13 SLA
  formalisation (p99 <200ms end-to-end) ✅
- Fallback strategies: Day 3 SLA table consistent with Day 13 SLA doc and
  Day 6 Saga compensating actions ✅

## Open questions closed

All open questions from Days 1-14 are now resolved:
- card-management: handled by Core Banking System ACL (Day 10)
- Sync vs async graph update: async chosen (Day 9)
- Critical path latency: 85ms p99 achieved via parallel detection (Days 3, 13)
- RBI vs GDPR conflict: jurisdiction-based ConfigMap (Day 10)
