# AI Usage Disclosure

**Date:** 14 July 2026

---

## AI Tool Used

Claude (Anthropic) was used throughout this project as a research,
drafting, and structuring assistant.

## What AI assisted with

| Area | AI assistance | My contribution |
|---|---|---|
| Document structure | Initial drafts of all markdown documents | Reviewed every section; modified terminology, design decisions, and justifications to reflect my own understanding; removed and rewrote sections that did not match my intended architecture |
| YAML/Protobuf/JSON configs | Initial schema structures (rule engine schema, Kafka proto, OpenAPI spec) | Reviewed all schemas against the project brief requirements; corrected field types, added missing fields, adjusted naming conventions |
| Cypher queries | Draft query patterns for graph analysis | Validated query logic against Neo4j documentation; adjusted partition strategies and WHERE clauses |
| Mermaid diagrams | Initial flowchart structures | Reviewed node placement, corrected relationship directions, verified consistency with architecture decisions |
| Kubernetes manifests | Draft Deployment, Service, HPA, PDB, NetworkPolicy | Reviewed resource limits, adjusted probe timings, verified security context settings |

## What I did independently

- All architectural decisions and their justifications (service boundaries,
  technology choices, data store selections, deployment strategy per service)
- Identification of the 5 embedded errors in the project brief
- All tradeoff analyses (sync vs async graph update, blue-green vs canary,
  ONNX Runtime vs TF Serving vs Triton)
- Interpretation and resolution of the RBI vs GDPR retention conflict
- The latency budget breakdown per hop
- Fallback strategy designs for each service
- All work logs documenting reasoning and open questions

