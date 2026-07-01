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
| 5 | API Contracts | ⬜ Pending |
| 6 | Event-Driven Architecture | ⬜ Pending |
| 7 | Rule Engine Design | ⬜ Pending |
| 8 | ML Architecture | ⬜ Pending |
| 9 | Graph Analysis | ⬜ Pending |
| 10 | Security Design | ⬜ Pending |
| 11 | API Gateway | ⬜ Pending |
| 12 | Monitoring | ⬜ Pending |
| 13 | Observability & SLAs | ⬜ Pending |
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
