# SWE-2C — Real-Time Fraud Detection Microservices Architecture

**Intern:** Aditi Sharma
**Project:** ShieldPay Financial Services — Platform Re-Architecture Simulation
**Timeline:** 15-day AI-Driven System Design & Architecture Project

## What this repository contains

This is the design and documentation repository for a microservices-based, real-time
fraud detection platform — built as a 15-day architecture sprint simulating the
decomposition of a legacy monolith (ShieldPay) into a modern, event-driven system using
rule engines, ML-based anomaly detection, and graph-based relationship analysis.

This is a **design project**, not a deployed system. The deliverables are architecture
documents, diagrams, schemas, and specifications — see each day's folder for detailed
reasoning and decisions.

## Repository structure

This repo is organised **day-first**: every deliverable from a given day lives together
under `docs/dayNN/`, regardless of whether it's a write-up, a diagram, a schema, or a
config file. This makes it easy to review one day's work as a complete unit (which is how
the Board evaluates it) without hunting across multiple top-level folders.

```
docs/
  day01/   — domain glossary, monolith analysis, event storming
  day02/   — bounded context map, C4 Level 1, service decomposition table
  day03/   — C4 Level 2/3, SLA table, persistence strategy
  ...      — one folder per day, through day15/
daily-commits/
  Day01_Domain_Immersion.md   — daily work logs (what was done, decisions, blockers)
  Day02_Service_Decomposition.md
  ...
```

Within each `docs/dayNN/` folder, files are numbered in the order they were produced
(`01_`, `02_`, ...) and named for their content (e.g. `01_domain_glossary.md`,
`03_event_storming.md`). Diagrams, API specs, and config files for that day live as
plain files inside the same folder rather than in separate type-based trees — e.g. Day 4's
Kafka topic YAML will be `docs/day04/02_kafka_topics.yaml`, not in a separate `/configs` folder.

`/daily-commits` stays a flat, separate folder (per the project brief's required
structure) since work logs are explicitly a distinct deliverable type from the
architecture artifacts themselves.

## Progress tracker

| Day | Focus | Status |
|---|---|---|
| 1 | Domain Immersion & Monolith Analysis | ✅ Complete |
| 2 | Service Decomposition | ✅ Complete |
| 3 | C4 Diagrams & SLAs | ✅ Complete |
| 4 | Kafka Design | ✅ Complete |
| 5 | API Contracts | ✅ Complete |
| 6 | Event-Driven Architecture | ✅ Complete |
| 7 | Rule Engine Design | ✅ Complete |
| 8 | ML Architecture | ✅ Complete |
| 9 | Graph Analysis | ✅ Complete |
| 10 | Security Design | ✅ Complete |
| 11 | API Gateway | ✅ Complete |
| 12 | Monitoring | ✅ Complete |
| 13 | Observability & SLAs | ✅ Complete |
| 14 | CI/CD & Deployment | ⬜ Pending |
| 15 | Final Assembly | ⬜ Pending |

## Day 1 deliverables (this commit)

- [`docs/day01/01_domain_glossary.md`](docs/day01/01_domain_glossary.md) — 54-term fraud detection domain glossary
- [`docs/day01/02_monolith_analysis.md`](docs/day01/02_monolith_analysis.md) — Legacy ShieldPay system analysis and business capability mapping
- [`diagrams/event-storming/day01_initial_event_storm.md`](diagrams/event-storming/day01_initial_event_storm.md) — Initial Event Storming pass on the transaction lifecycle
- [`daily-commits/Day01_Domain_Immersion.md`](daily-commits/Day01_Domain_Immersion.md) — Day 1 work log

## Day 2 deliverables

- [`docs/day02/01_bounded_context_map.md`](docs/day02/01_bounded_context_map.md) — 9 bounded contexts + Reference Data, with context mapping patterns
- [`diagrams/c4/day02_c4_level1_system_context.md`](diagrams/c4/day02_c4_level1_system_context.md) — C4 Level 1 System Context diagram
- [`diagrams/c4/day02_c4_level2_container_draft.md`](diagrams/c4/day02_c4_level2_container_draft.md) — C4 Level 2 Container diagram (draft, finalized Day 3)
- [`docs/day02/02_service_decomposition_table.md`](docs/day02/02_service_decomposition_table.md) — 10-service decomposition table (tech, data store, team ownership)
- [`daily-commits/Day02_Service_Decomposition.md`](daily-commits/Day02_Service_Decomposition.md) — Day 2 work log

## Day 3 deliverables

- [`diagrams/c4/day03_c4_level2_final.md`](diagrams/c4/day03_c4_level2_final.md) — C4 Level 2 Container diagram (final) with latency budget breakdown
- [`diagrams/c4/day03_c4_level3_components.md`](diagrams/c4/day03_c4_level3_components.md) — C4 Level 3 Component diagrams for 4 core services
- [`docs/day03/01_service_sla_table.md`](docs/day03/01_service_sla_table.md) — Service SLA table (Tiers 1-3) with fallback behaviours
- [`docs/day03/02_polyglot_persistence.md`](docs/day03/02_polyglot_persistence.md) — Polyglot persistence justification
- [`daily-commits/Day03_C4_Diagrams.md`](daily-commits/Day03_C4_Diagrams.md) — Day 3 work log

## Day 4 deliverables

- [`docs/day04/01_kafka_topic_topology.md`](docs/day04/01_kafka_topic_topology.md) — Kafka topic topology (10 topics, partition rationale, DLQ strategy)
- [`configs/kafka_event_schemas.proto`](configs/kafka_event_schemas.proto) — Protobuf event schema definitions for all topics
- [`configs/schema_registry_config.yaml`](configs/schema_registry_config.yaml) — Schema Registry configuration with compatibility levels
- [`daily-commits/Day04_Kafka_Design.md`](daily-commits/Day04_Kafka_Design.md) — Day 4 work log

## AI usage disclosure

See `/docs/AI_USAGE.md` (to be added) for disclosure of AI-assisted content per the
project's AI-Assisted Development Policy (Section E5).

## Day 5 deliverables

- [`api-specs/openapi.yaml`](api-specs/openapi.yaml) — OpenAPI 3.0 spec for all 6 external REST APIs
- [`api-specs/fraud_grpc_services.proto`](api-specs/fraud_grpc_services.proto) — Protobuf gRPC service definitions (6 services)
- [`docs/day05/01_api_gateway_routing.md`](docs/day05/01_api_gateway_routing.md) — Gateway routing table, rate limiting, auth flows, circuit breaker
- [`daily-commits/Day05_API_Contracts.md`](daily-commits/Day05_API_Contracts.md) — Day 5 work log

## Day 6 deliverables

- [`diagrams/event-storming/day06_full_event_storm.md`](diagrams/event-storming/day06_full_event_storm.md) — Full Event Storming (55 events, 4 aggregates, policies)
- [`docs/day06/01_saga_orchestration.md`](docs/day06/01_saga_orchestration.md) — 3 Saga diagrams with compensating transactions + CQRS read models
- [`daily-commits/Day06_EDA_Specification.md`](daily-commits/Day06_EDA_Specification.md) — Day 6 work log

## Day 7 deliverables

- [`configs/rule_engine_schema.yaml`](configs/rule_engine_schema.yaml) — Rule definition YAML schema
- [`configs/rule_engine_schema.json`](configs/rule_engine_schema.json) — JSON Schema for validation
- [`configs/sample_rules.yaml`](configs/sample_rules.yaml) — 20 sample rules across 7 categories
- [`docs/day07/01_rule_lifecycle_and_simulation.md`](docs/day07/01_rule_lifecycle_and_simulation.md) — Lifecycle state machine, simulation spec, A/B testing, performance monitoring
- [`daily-commits/Day07_Rule_Engine_Design.md`](daily-commits/Day07_Rule_Engine_Design.md) — Day 7 work log

## Day 8 deliverables

- [`docs/day08/01_ml_serving_architecture.md`](docs/day08/01_ml_serving_architecture.md) — Model registry, deployment pipeline, ONNX Runtime, feature store, ensemble, monitoring, champion-challenger
- [`daily-commits/Day08_ML_Architecture.md`](daily-commits/Day08_ML_Architecture.md) — Day 8 work log

## Day 9 deliverables

- [`docs/day09/01_graph_schema.md`](docs/day09/01_graph_schema.md) — Property graph schema: 9 node types, 10 relationship types, all indexes
- [`docs/day09/02_cypher_queries.md`](docs/day09/02_cypher_queries.md) — 5 Cypher query patterns + 3 fraud topology templates with sample data
- [`docs/day09/03_graph_sync_and_maintenance.md`](docs/day09/03_graph_sync_and_maintenance.md) — Async update strategy, reconciliation, pruning, read replica design
- [`diagrams/graph/day09_graph_schema_diagram.md`](diagrams/graph/day09_graph_schema_diagram.md) — Entity relationship diagram
- [`daily-commits/Day09_Graph_Analysis_Design.md`](daily-commits/Day09_Graph_Analysis_Design.md) — Day 9 work log

## Day 10 deliverables

- [`configs/istio/peer_authentication.yaml`](configs/istio/peer_authentication.yaml) — Strict mTLS namespace-wide, zero exceptions
- [`configs/istio/authorization_policies.yaml`](configs/istio/authorization_policies.yaml) — Default-deny + per-service least-privilege allows
- [`configs/istio/destination_rules.yaml`](configs/istio/destination_rules.yaml) — Connection pools, TLS, outlier detection per service
- [`configs/istio/virtual_services.yaml`](configs/istio/virtual_services.yaml) — Blue-green (Rule Engine) and canary (Anomaly Detection) routing
- [`docs/day10/01_service_communication_matrix.md`](docs/day10/01_service_communication_matrix.md) — 11×11 allowed connections matrix
- [`docs/day10/02_encryption_strategy.md`](docs/day10/02_encryption_strategy.md) — AES-256 at rest, mTLS in transit, PAN tokenisation, key rotation
- [`docs/day10/03_pci_dss_compliance_mapping.md`](docs/day10/03_pci_dss_compliance_mapping.md) — PCI DSS, RBI, GDPR requirement-to-component mapping
- [`daily-commits/Day10_Security_Design.md`](daily-commits/Day10_Security_Design.md) — Day 10 work log

## Day 11 deliverables

- [`docs/day11/01_api_gateway_config.md`](docs/day11/01_api_gateway_config.md) — Kong declarative config for all 5 routes with plugins
- [`docs/day11/02_rate_limiting_policy.md`](docs/day11/02_rate_limiting_policy.md) — 5-tier rate limiting framework with Redis counter design
- [`docs/day11/03_auth_flow_diagrams.md`](docs/day11/03_auth_flow_diagrams.md) — JWT, API Key, and analyst role-based auth flows
- [`daily-commits/Day11_Gateway_Design.md`](daily-commits/Day11_Gateway_Design.md) — Day 11 work log

## Day 12 deliverables

- [`configs/monitoring/prometheus_rules.yaml`](configs/monitoring/prometheus_rules.yaml) — Recording rules + P1-P4 alerting rules
- [`docs/day12/01_grafana_dashboards.md`](docs/day12/01_grafana_dashboards.md) — 4 dashboard specs + Alertmanager routing config
- [`docs/day12/02_runbooks.md`](docs/day12/02_runbooks.md) — P1-001, P1-002, P2-001, P2-002 runbooks with kubectl commands
- [`daily-commits/Day12_Monitoring_Design.md`](daily-commits/Day12_Monitoring_Design.md) — Day 12 work log

## Day 13 deliverables

- [`configs/observability/logging_standard.md`](configs/observability/logging_standard.md) — Structured JSON logging standard, PII masking rules, retention policy, Fluent Bit pipeline
- [`configs/observability/tracing_config.yaml`](configs/observability/tracing_config.yaml) — OpenTelemetry collector config, sampling strategy, custom span attributes, Kafka trace propagation
- [`docs/day13/01_sla_specification.md`](docs/day13/01_sla_specification.md) — Final SLA document: pipeline SLAs, per-service SLAs, error budget policy, latency budget breakdown
- [`daily-commits/Day13_Observability_Design.md`](daily-commits/Day13_Observability_Design.md) — Day 13 work log
