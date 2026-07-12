# Day 14 Work Log — CI/CD Pipeline and Deployment Strategy

**Date:** 12 July 2026
**Commit tag:** `Day14_CICD_Deployment`

## What I did
- Designed 7-stage CI/CD pipeline (Source → Build → Test → Scan → Stage → Canary → Production)
  using GitHub Actions + ArgoCD GitOps.
- Wrote full GitHub Actions workflow for rule-engine-svc (blue-green) with automated rollback.
- Documented differentiated deployment strategy per service.
- Wrote DR plan: multi-region topology (Mumbai primary, Singapore secondary),
  RPO/RTO per tier, Route 53 failover runbook with exact CLI commands.
- Designed 5 chaos engineering experiments (Section A4.3 + B2 badge criteria).
- Wrote sample Dockerfiles: rule-engine-svc (Java/distroless), anomaly-detection-svc (Python/slim).
- Wrote complete Kubernetes manifests for rule-engine-svc: Deployment, Service,
  HPA (CPU + memory + Kafka lag custom metric), PodDisruptionBudget, NetworkPolicy.

## Key decisions made
1. Blue-green for rule-engine-svc — rules must switch atomically, not gradually.
2. HPA scales on Kafka consumer lag (custom metric) — direct indicator for event-driven services.
3. PodDisruptionBudget minAvailable=2 — prevents total eviction during node maintenance.
4. Automated rollback in blue-green — monitors 10 minutes post-switch, auto-reverts on >1% errors.
5. Expand-Contract for DB schema migrations — zero-downtime schema changes.
