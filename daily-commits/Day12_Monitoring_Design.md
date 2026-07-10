# Day 12 Work Log — Monitoring Dashboard and Alerting Specification

**Date:** 10 July 2026
**Commit tag:** `Day12_Monitoring_Design`

## What I did
- Wrote Prometheus recording rules (pre-computed metrics for dashboard speed)
  and alerting rules across P1 (4 alerts), P2 (5 alerts), P3 (2 alerts),
  P4 (1 alert) severity tiers.
- Designed 4 Grafana dashboards: Transaction Processing, Fraud Detection,
  Case Management, Infrastructure — each with panel-level query and threshold.
- Wrote Alertmanager routing config with severity-based routing to
  PagerDuty (P1), Slack (P2), daily email digest (P3), weekly digest (P4).
- Wrote P1-001 (pipeline down), P1-002 (detection collapsed), P2-001
  (service error rate), P2-002 (Kafka lag) runbooks with exact kubectl
  commands, root cause table, and escalation path.

## Key decisions made
1. **Recording rules pre-compute all dashboard queries** — a Grafana dashboard
   running live PromQL against millions of data points on every 15s refresh
   would overload Prometheus. Recording rules compute and store the results
   every 15s; dashboards query the pre-computed series instead.
2. **P1-002 (detection collapsed) threshold set at 0.2% decline+review rate**
   — normal combined rate is ~3-5% (0.5% auto-decline + 2-4% step-up/review).
   0.2% means the detection is essentially off — justifies immediate P1 response.
3. **P3 alerts grouped into daily digest, not immediate notification** —
   P3 issues (FP rate creeping up, non-critical service degradation) are real
   but not emergencies. Immediate notification would cause alert fatigue
   (the exact failure mode in the Target breach case study, Part C1).
4. **Runbooks include exact kubectl commands, not just descriptions** —
   at 2am during a P1, an on-call engineer needs copy-paste commands,
   not a description of what to investigate.
