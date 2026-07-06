# Day 7 Work Log — Rule Engine Configuration Framework

**Date:** 6 July 2026
**Commit tag:** `Day07_Rule_Engine_Design`

## What I did
- Designed YAML schema for rule definitions supporting nested AND/OR/NOT conditions,
  temporal windows, entity scopes, 5 action types, and A/B test configuration.
- Wrote JSON Schema for validation at rule-save time (prevents malformed rules
  reaching production).
- Created 20 sample rules across all 7 categories (VELOCITY×5, AMOUNT×3,
  GEOGRAPHIC×3, MCC×3, WATCHLIST×2, BEHAVIOURAL×2, DEVICE×2).
- Designed rule lifecycle state machine (DRAFT→REVIEW→APPROVED→ACTIVE→DEPRECATED→RETIRED)
  with role-based permissions per transition.
- Specified rule simulation: automatic 30-day backtest before any rule can be activated,
  with FP rate >1% blocking activation.
- Documented A/B shadow testing with automated daily comparison reports and
  quantified promotion criteria.
- Designed per-rule Prometheus metrics (trigger rate, TP rate, FP rate, latency).

## Key decisions made
1. **FP rate >1% blocks activation** — not just a warning. A rule with 1%+ FP rate
   on 2.4M daily transactions = 24,000+ false positives per day. That is not a
   production-acceptable rule.
2. **Rules are never deleted, only archived** — audit requirement. A regulator must
   be able to see which rule was active at any point in time when investigating a
   past fraud decision.
3. **Rule evaluation time capped at max_evaluation_time_ms per rule** — without this,
   a poorly written temporal aggregation query could blow the 50ms total rule-set budget.
4. **Simulation uses time-based holdout split, not random** — random splits leak
   future information into the past (data leakage), making simulation metrics
   unrealistically optimistic.

## Tomorrow's plan (Day 8)
- ML model serving architecture: model registry, deployment pipeline, ONNX Runtime
  justification, feature store (batch + real-time tiers), ensemble strategy,
  model monitoring pipeline, champion-challenger framework.
