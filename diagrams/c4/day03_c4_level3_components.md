# C4 Level 3 — Component Diagrams (4 Core Services)

**Day 3 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 30 June 2026

> C4 Level 3 zooms into individual containers and shows the internal components
> that make each service work. Required for: Transaction Ingestion, Rule Engine,
> Anomaly Detection, Risk Scoring.

---

## Service 1: transaction-ingestion-svc

```mermaid
flowchart TB
    subgraph TI["transaction-ingestion-svc (Go)"]
        API["REST/gRPC Handler\nValidates schema, assigns trace_id"]
        NORM["Channel Normaliser\nTranslates ISO 8583 / UPI / REST\ninto internal TransactionEvent schema"]
        ENRICH["Enrichment Orchestrator\nCalls device FP + IP geo concurrently"]
        PUB["Kafka Producer\nPublishes fraud.transactions.enriched"]
        HEALTH["Health Check /healthz"]
        METRICS["Prometheus Metrics Exporter"]
        CFG["Config Loader (Vault secrets)"]
    end

    EXT["External Channel"] -->|"raw transaction"| API
    API --> NORM --> ENRICH --> PUB
    ENRICH --> FP["ThreatMetrix API"]
    ENRICH --> GEO["MaxMind API"]
    PUB --> KAFKA[("Kafka")]
    PUB --> DB[("PostgreSQL staging")]

    classDef comp fill:#B5D4F4,stroke:#185FA5,color:#042C53
    classDef infra fill:#E8E8E8,stroke:#888,color:#333
    classDef ext fill:#CECBF6,stroke:#534AB7,color:#26215C
    class API,NORM,ENRICH,PUB,HEALTH,METRICS,CFG comp
    class KAFKA,DB infra
    class EXT,FP,GEO ext
```

**Key decisions:** Enrichment runs concurrent goroutines to stay within 20ms budget.
Config Loader pulls secrets from Vault at startup — never baked into the image.

---

## Service 2: rule-engine-svc

```mermaid
flowchart TB
    subgraph RE["rule-engine-svc (Java)"]
        GRPC["gRPC Server — Evaluate RPC\nDeadline: 50ms"]
        MGMT["Rule Management REST API\nGET/POST/PUT /rules"]
        PARSER["Rule Parser\nCompiles YAML/JSON to executable form"]
        CACHE["In-Memory Rule Cache\nReloaded on rule change event"]
        EVAL["Condition Evaluator\nAND/OR/NOT with short-circuit"]
        TAGG["Temporal Aggregator\nSliding window counts/sums"]
        ACTION["Action Executor\nflag / block / score_adjust / step_up_auth"]
        METRICS["Per-rule metrics: trigger rate, FP rate, latency"]
    end

    KAFKA[("fraud.transactions.enriched")] --> GRPC
    GRPC --> CACHE --> EVAL --> TAGG --> EVAL --> ACTION
    ACTION --> PUB[("fraud.rule.results")]
    MGMT --> PARSER --> CACHE
    DB_RE[("PostgreSQL rules")] --- PARSER
    REDIS[("Redis temporal state")] --- TAGG

    classDef comp fill:#B5D4F4,stroke:#185FA5,color:#042C53
    classDef infra fill:#E8E8E8,stroke:#888,color:#333
    class GRPC,MGMT,PARSER,CACHE,EVAL,TAGG,ACTION,METRICS comp
    class KAFKA,PUB,DB_RE,REDIS infra
```

**Key decisions:** Rules compiled to in-memory cache — no DB hit on hot path.
Temporal Aggregator persists window state in Redis so pod restarts don't lose velocity counts.
Rule Management API is a separate HTTP endpoint — cannot block live evaluation.

---

## Service 3: anomaly-detection-svc

```mermaid
flowchart TB
    subgraph AD["anomaly-detection-svc (Python/FastAPI)"]
        GRPC_S["gRPC Server — Score RPC\nDeadline: 30ms"]
        FEAT["Feature Retriever\nReads from Redis/Feast sub-1ms"]
        ENG["ONNX Inference Engine\nSupervised + unsupervised models\npre-loaded into memory at startup"]
        ENSEMBLE["Ensemble Layer\nWeighted avg of model scores"]
        SHAP["Explainability — SHAP values\nTop 5 contributing features"]
        MONITOR["Model Monitor\nPSI (data drift) + KS test (prediction drift)"]
        WARMUP["Warm-up on container start\nLoads all model artifacts from MLflow"]
    end

    KAFKA[("fraud.transactions.enriched")] --> GRPC_S
    GRPC_S --> FEAT --> ENG --> ENSEMBLE --> SHAP
    SHAP --> PUB[("fraud.anomaly.scores")]
    REDIS[("Redis/Feast feature store")] --- FEAT
    MLFLOW[("MLflow model registry")] --- WARMUP --> ENG
    MONITOR --> ALERT["Prometheus drift alert"]

    classDef comp fill:#B5D4F4,stroke:#185FA5,color:#042C53
    classDef infra fill:#E8E8E8,stroke:#888,color:#333
    class GRPC_S,FEAT,ENG,ENSEMBLE,SHAP,MONITOR,WARMUP comp
    class KAFKA,PUB,REDIS,MLFLOW,ALERT infra
```

**Key decisions:** Models pre-loaded at container start (no cold-start latency).
ONNX Runtime chosen for cross-framework portability.
SHAP values computed inline per decision — explainability is a per-decision regulatory requirement.

---

## Service 4: risk-scoring-svc

```mermaid
flowchart TB
    subgraph RS["risk-scoring-svc (Go)"]
        CONSUMER["Kafka Consumer\nfraud.rule.results +\nfraud.anomaly.scores +\nfraud.graph.signals"]
        CORRELATOR["Signal Correlator\nWaits for all 3 signals\nfor same transaction_id\n(timeout: 80ms)"]
        AGG["Score Aggregator\nw1×RuleScore + w2×MLScore\n+ w3×GraphScore\n(configurable weights)"]
        THRESH["Threshold Engine\nApplies market/channel/product\nconfigurable thresholds"]
        EXPLAIN["Explanation Builder\nWhich rules triggered,\ntop SHAP features,\ngraph signals"]
        PUBLISHER["Kafka Producer\nfraud.risk.decisions\nfraud.alerts\nnotifications.outbound\nfraud.audit.events"]
    end

    T3[("fraud.rule.results")] --> CONSUMER
    T4[("fraud.anomaly.scores")] --> CONSUMER
    T5[("fraud.graph.signals")] --> CONSUMER
    CONSUMER --> CORRELATOR --> AGG --> THRESH --> EXPLAIN --> PUBLISHER
    DB_RS[("PostgreSQL decisions")] --- EXPLAIN
    CFG[("ConfigMap thresholds")] --- THRESH

    classDef comp fill:#B5D4F4,stroke:#185FA5,color:#042C53
    classDef infra fill:#E8E8E8,stroke:#888,color:#333
    class CONSUMER,CORRELATOR,AGG,THRESH,EXPLAIN,PUBLISHER comp
    class T3,T4,T5,DB_RS,CFG infra
```

**Key decisions:** Signal Correlator has 80ms timeout — if Graph Analysis misses
the window, scoring proceeds with Rule + ML only (score adjusted upward by
configurable safety margin). Thresholds live in ConfigMaps — changeable without
a code deployment.
