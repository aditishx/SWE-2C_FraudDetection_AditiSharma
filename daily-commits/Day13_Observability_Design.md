# Day 13 Work Log — Logging, Tracing and SLA Specification

**Date:** 11 July 2026
**Commit tag:** `Day13_Observability_Design`

## What I did
- Wrote structured logging standard: mandatory JSON fields, optional context fields,
  PII masking rules enforced at library level, log levels guide, retention policy
  (90-day hot Elasticsearch + 7-year cold S3 Glacier), Fluent Bit pipeline config.
- Wrote OpenTelemetry tracing configuration: OTEL Collector setup, SDK env vars,
  sampling strategy (10% base + 100% for slow/error/fraud traces), custom span
  attributes per service, trace context propagation across gRPC and Kafka boundaries.
- Wrote final formalised SLA document: end-to-end pipeline SLAs, per-service SLAs
  across 3 tiers, error budget policy (freeze deployments at 75% consumed), measurement
  methodology for latency/availability/fraud rate/FP rate, breach response matrix,
  and full latency budget breakdown per hop (Latency Hunter badge criteria, Section B2).

## Key decisions made
1. **PII masking enforced at library level, not developer discipline** — the PAN
   type in the codebase has a custom toString() returning the hash. Developers
   cannot accidentally log a raw PAN. Relying on developers to remember never to
   log a PAN is a PCI DSS audit risk that one tired developer will eventually fail.
2. **10% base sampling rate with 100% override for slow/error/fraud traces** —
   10% base gives statistical accuracy for latency percentiles (±2% error by CLT)
   without storing 50,000 traces/second. 100% capture for slow and fraud traces
   means we never lose a trace when we actually need to investigate something.
   This is head-based sampling with tail-based override logic.
3. **trace_id embedded in Kafka message payload AND headers** — Kafka message headers
   carry W3C TraceContext for consumers that support it. Payload-level trace_id is
   the fallback. Without both, the distributed trace breaks at every async boundary
   and you cannot reconstruct the full transaction timeline across Kafka topics.
4. **Error budget at 75% consumed triggers deployment freeze** — not at 100%.
   Waiting until the budget is fully exhausted before acting means the next incident
   happens with zero remaining buffer. Freezing at 75% leaves headroom for one more
   incident while still protecting the monthly SLA.
5. **Latency measured as percentiles, never averages** — averages hide tail latency.
   A service with p50=10ms and p99=800ms has a "good average" of ~15ms but is
   failing 1% of users badly. Percentile SLAs expose this; averages mask it.

## Open questions / things to revisit
- DEBUG log auto-disable after 30 minutes via ConfigMap update needs an implementation
  detail: the Fluent Bit DaemonSet must watch the ConfigMap and reload dynamically.
  This is a Day 14 concern — the CI/CD pipeline should include a mechanism for
  per-service log-level changes without a pod restart.
