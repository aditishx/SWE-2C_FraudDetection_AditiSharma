# Day 4 Work Log — Kafka Topic Design and Event Schemas

**Date:** 1 July 2026
**Hours logged:** ~8h
**Commit tag:** `Day04_Kafka_Design`

## What I did
- Designed 10 Kafka topics covering the complete transaction lifecycle (exceeds the 8-topic minimum from Section D2).
- Defined Protobuf schemas for all event types: TransactionEvent, EnrichedTransactionEvent, RuleEvaluationResult, AnomalyScore, GraphSignals, RiskDecision, AuditEvent, NotificationRequest.
- Configured Schema Registry with BACKWARD compatibility for all operational topics and FULL compatibility for audit.events (stricter, because regulators must be able to query any schema version).
- Designed DLQ topology with per-source-topic DLQ topics, retention policies, and alert severity mappings.

## Key decisions made
1. **`card_number_hash` as partition key for transaction topics** — ensures all transactions for a given card land in the same partition and consumer instance, which is a hard requirement for the Temporal Aggregator's velocity counting (Section A1.4).
2. **`transaction_id` as partition key for result topics** — ensures that Rule, ML, and Graph results for the same transaction land in the same partition, so the Signal Correlator in Risk Scoring sees them together.
3. **48 partitions for critical-path topics** — sized for 50,000 TPS peak with ~1,000 msg/partition/sec and headroom.
4. **AuditEvent includes `hash` and `previous_hash` fields** — implements a Merkle chain directly in the schema, so tampering is detectable by anyone who can read the topic, not just the audit service.
5. **FULL compatibility for fraud.audit.events** — regulators querying historical audit records may use any schema version; FULL guarantees bidirectional compatibility across all versions.

## Open questions / things to revisit
- Exact partition count may need tuning once real TPS benchmarks are available — 48 is a reasonable starting point but should be treated as a configurable parameter, not a hardcoded constraint.

## Tomorrow's plan (Day 5)
- Create OpenAPI 3.0 specifications for all external-facing REST APIs.
- Define Protobuf service definitions for all internal gRPC services.
- Design the API gateway routing table.
