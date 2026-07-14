# SWE-2C — Real-Time Fraud Detection Microservices Architecture

**Intern:** Aditi Sharma
**Project:** ShieldPay Financial Services — Platform Re-Architecture Simulation
**Timeline:** 15-day AI-Driven System Design & Architecture Project
**Status:** ✅ Complete — submitted 14 July 2026

---

## Quick Navigation

| Document | Location |
|---|---|
| **Master Architecture Document** | [`docs/master/MASTER_ARCHITECTURE_DOCUMENT.md`](docs/master/MASTER_ARCHITECTURE_DOCUMENT.md) |
| **Error Detection (5 errors found)** | [`docs/day15/ERROR_DETECTION.md`](docs/day15/ERROR_DETECTION.md) |
| **AI Usage Disclosure** | [`docs/AI_USAGE.md`](docs/AI_USAGE.md) |
| Domain Glossary | [`docs/day01/01_domain_glossary.md`](docs/day01/01_domain_glossary.md) |
| Bounded Context Map | [`docs/day02/01_bounded_context_map.md`](docs/day02/01_bounded_context_map.md) |
| C4 Level 1 — System Context | [`diagrams/c4/day02_c4_level1_system_context.md`](diagrams/c4/day02_c4_level1_system_context.md) |
| C4 Level 2 — Container (final) | [`diagrams/c4/day03_c4_level2_final.md`](diagrams/c4/day03_c4_level2_final.md) |
| C4 Level 3 — Components (4 services) | [`diagrams/c4/day03_c4_level3_components.md`](diagrams/c4/day03_c4_level3_components.md) |
| Kafka Topic Topology | [`docs/day04/01_kafka_topic_topology.md`](docs/day04/01_kafka_topic_topology.md) |
| Protobuf Event Schemas | [`configs/kafka_event_schemas.proto`](configs/kafka_event_schemas.proto) |
| OpenAPI 3.0 Specification | [`api-specs/openapi.yaml`](api-specs/openapi.yaml) |
| gRPC Service Definitions | [`api-specs/fraud_grpc_services.proto`](api-specs/fraud_grpc_services.proto) |
| Event Storming (55 events) | [`diagrams/event-storming/day06_full_event_storm.md`](diagrams/event-storming/day06_full_event_storm.md) |
| Saga Orchestration | [`docs/day06/01_saga_orchestration.md`](docs/day06/01_saga_orchestration.md) |
| Rule Engine Schema + 20 Rules | [`configs/rule_engine_schema.yaml`](configs/rule_engine_schema.yaml) · [`configs/sample_rules.yaml`](configs/sample_rules.yaml) |
| ML Serving Architecture | [`docs/day08/01_ml_serving_architecture.md`](docs/day08/01_ml_serving_architecture.md) |
| Graph Schema + Cypher Queries | [`docs/day09/01_graph_schema.md`](docs/day09/01_graph_schema.md) · [`docs/day09/02_cypher_queries.md`](docs/day09/02_cypher_queries.md) |
| Istio Config (mTLS + AuthZ) | [`configs/istio/`](configs/istio/) |
| PCI DSS / RBI / GDPR Mapping | [`docs/day10/03_pci_dss_compliance_mapping.md`](docs/day10/03_pci_dss_compliance_mapping.md) |
| Rate Limiting Policy (5 tiers) | [`docs/day11/02_rate_limiting_policy.md`](docs/day11/02_rate_limiting_policy.md) |
| Prometheus Rules + Runbooks | [`configs/monitoring/prometheus_rules.yaml`](configs/monitoring/prometheus_rules.yaml) · [`docs/day12/02_runbooks.md`](docs/day12/02_runbooks.md) |
| Final SLA Specification | [`docs/day13/01_sla_specification.md`](docs/day13/01_sla_specification.md) |
| CI/CD Pipeline + DR Plan | [`docs/day14/01_cicd_pipeline.md`](docs/day14/01_cicd_pipeline.md) · [`docs/day14/02_dr_plan.md`](docs/day14/02_dr_plan.md) |
| Sample Dockerfiles | [`samples/dockerfiles/`](samples/dockerfiles/) |
| Kubernetes Manifests | [`samples/k8s/`](samples/k8s/) |

---

## Repository Structure

```
SWE-2C_FraudDetection_AditiSharma/
├── api-specs/          OpenAPI YAML + Protobuf .proto files
├── configs/            Kafka schemas, Istio, Prometheus, logging, tracing
│   ├── istio/
│   ├── monitoring/
│   └── observability/
├── daily-commits/      Daily work logs (Day 1-15)
├── diagrams/           C4, Event Storming, Graph schema diagrams
│   ├── c4/
│   ├── event-storming/
│   └── graph/
├── docs/               Design documents (day01/ through day15/ + master/)
│   └── master/         Master Architecture Document
├── presentation/       Board presentation (Day 15)
└── samples/            Dockerfiles + Kubernetes manifests
    ├── dockerfiles/
    └── k8s/
```

---

## Progress

| Day | Focus | Status |
|---|---|---|
| 1 | Domain Immersion | ✅ Complete |
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
| 14 | CI/CD & Deployment | ✅ Complete |
| 15 | Final Assembly | ✅ Complete |

---

