# Kafka Topic Topology

**Day 4 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 1 July 2026

> Apache Kafka is the event backbone for the entire platform. This document defines
> every topic, its partitioning strategy, retention policy, consumer groups, and
> the dead-letter queue (DLQ) topology for poison message handling.

## Naming convention

All topics follow: `domain.entity.action`
Example: `fraud.transactions.raw`, `fraud.audit.events`

## Topic inventory (8 core topics)

| # | Topic Name | Partitions | Replication | Retention | Key Schema | Producers | Consumer Groups |
|---|---|---|---|---|---|---|---|
| 1 | `fraud.transactions.raw` | 48 | 3 | 30 days | `card_number_hash` | transaction-ingestion-svc | ingestion-enrichment-cg |
| 2 | `fraud.transactions.enriched` | 48 | 3 | 30 days | `card_number_hash` | transaction-ingestion-svc | rule-engine-cg, anomaly-detection-cg, graph-analysis-cg |
| 3 | `fraud.rule.results` | 48 | 3 | 7 days | `transaction_id` | rule-engine-svc | risk-scoring-cg, audit-cg |
| 4 | `fraud.anomaly.scores` | 48 | 3 | 7 days | `transaction_id` | anomaly-detection-svc | risk-scoring-cg, audit-cg |
| 5 | `fraud.graph.signals` | 48 | 3 | 7 days | `transaction_id` | graph-analysis-svc | risk-scoring-cg, audit-cg |
| 6 | `fraud.risk.decisions` | 48 | 3 | 90 days | `transaction_id` | risk-scoring-svc | case-management-cg, audit-cg, analytics-cg |
| 7 | `fraud.alerts` | 24 | 3 | 30 days | `card_number_hash` | risk-scoring-svc | notification-cg, audit-cg |
| 8 | `notifications.outbound` | 24 | 3 | 7 days | `customer_id_hash` | risk-scoring-svc, case-management-svc | notification-svc-cg |
| 9 | `fraud.audit.events` | 12 | 3 | **Infinite** | `trace_id` | All services | audit-compliance-cg |
| 10 | `graph.updates` | 24 | 3 | 7 days | `entity_id` | transaction-ingestion-svc | graph-analysis-cg |

## Partition count rationale

- **48 partitions** for the critical path topics (1-6): based on target peak throughput
  of 50,000 TPS and target consumer parallelism. At 48 partitions with ~1,000
  messages/partition/second, the system comfortably handles 48,000 TPS with headroom.
- **24 partitions** for downstream topics (7-8, 10): lower throughput, fewer consumers.
- **12 partitions** for audit (9): audit writes are lower frequency than transactions;
  the bottleneck here is storage, not throughput.

## Partitioning key rationale

- **`card_number_hash`** for transaction topics: ensures ALL transactions for a given
  card go to the same partition and therefore the same consumer instance. This is
  critical for stateful pattern detection — the Temporal Aggregator in rule-engine-svc
  needs to see all transactions from card X in order to count "5 transactions in 10
  minutes from the same card."
- **`transaction_id`** for result topics: the signal correlator in risk-scoring-svc
  needs to match Rule + ML + Graph results for the same transaction — using
  transaction_id as the key guarantees they land in the same partition.

## DLQ (Dead Letter Queue) topology

Every consumer group has a corresponding DLQ topic for messages that fail
deserialization or processing after 3 retries:

| Source Topic | DLQ Topic | Retention | Alert |
|---|---|---|---|
| fraud.transactions.enriched | fraud.transactions.enriched.dlq | 30 days | P2 alert if DLQ count >100/hour |
| fraud.rule.results | fraud.rule.results.dlq | 7 days | P2 alert if any message lands here |
| fraud.anomaly.scores | fraud.anomaly.scores.dlq | 7 days | P2 alert |
| fraud.graph.signals | fraud.graph.signals.dlq | 7 days | P2 alert |
| fraud.risk.decisions | fraud.risk.decisions.dlq | 30 days | P1 alert — a missed decision is a fraud risk |
| notifications.outbound | notifications.outbound.dlq | 7 days | P3 alert — retry queue handles most failures |

DLQ messages include: original message payload, failure reason, retry count,
failing service name, and timestamp. A dedicated DLQ monitoring dashboard
(part of Day 12 Grafana dashboards) tracks DLQ growth rate per topic.
