# Legacy Monolith Analysis — ShieldPay Fraud Detection System

**Day 1 Deliverable | SWE-2C Fraud Detection Microservices Architecture**

## 1. Current State Summary

| Attribute | Value |
|---|---|
| Language/Stack | Java, deployed as WAR files on Apache Tomcat 8.5 |
| Codebase size | 1.2 million lines of code, built 2012, 12 years of accretion |
| Database | Single Oracle 19c instance — 45 TB, ~3s analytical query time |
| Rule storage | 500+ rules hardcoded in Java `switch` statements (no external config) |
| ML scoring | Batch job every 15 minutes (logistic regression, retrained every 6 months) |
| Deployment | Manual, 4-hour maintenance window every Saturday night |
| Infrastructure | Bare-metal, co-located data centre in Mumbai. No containers, no service mesh |
| Resilience | Single point of failure — Oracle DB has no read replicas, no cross-region replication |
| Volume | 2.4 million transactions/day across India, SE Asia, Middle East |

## 2. Business Capability Mapping

A **business capability** is "what the business does," independent of how it's currently implemented. Mapping the monolith's *code* to *capabilities* is the first step toward finding good service boundaries (Day 2).

| Monolith Functional Area | Business Capability | Notes |
|---|---|---|
| Java switch-statement rule logic | **Fraud Rule Evaluation** | Currently inflexible — any rule change requires a code deploy + the 4-hour maintenance window. |
| Batch cron job (15-min cycle) | **Anomaly / ML Scoring** | The 15-minute gap is a known, exploited weakness (see Crisis Q3 2025, batch-gap exploitation). |
| (Does not exist today) | **Graph-Based Relationship Analysis** | No current capability — synthetic identity rings go undetected. This is a *new* capability we're adding, not migrating. |
| Oracle stored procedures for score aggregation | **Risk Scoring & Decisioning** | Tightly coupled to rule + ML modules; thresholds are hardcoded. |
| Case queue tables + UI screens | **Case Management** | Manual analyst assignment, no SLA enforcement visible in legacy design. |
| Email/SMS dispatch module | **Notification** | Single channel logic, no localisation framework mentioned. |
| Oracle audit tables | **Audit & Compliance** | Mutable tables — no cryptographic integrity guarantee, a key Wirecard-style risk (see Part C4). |
| Customer table + computed columns | **Customer Profile** | Profile updates likely batch-driven given DB architecture, not real-time. |
| Static lookup tables (MCC, BIN, country risk) | **Reference Data** | Centralised in the same Oracle instance — a scaling/coupling risk. |
| Tomcat HTTP listeners | **Transaction Ingestion** | All channels (POS, e-com, UPI, ATM) funnel through one ingestion layer with no per-channel isolation. |

## 3. External System Integrations (documented today, formalised as C4 Level 1 on Day 2)

| External System | Interaction | Protocol (assumed legacy) |
|---|---|---|
| Card Payment Networks (Visa, Mastercard, RuPay) | Sends transaction authorisation requests | Likely ISO 8583 / proprietary batch files |
| Core Banking System | Provides balance/account status | Synchronous call or nightly batch reconciliation |
| Customer Mobile App | Receives notifications, step-up auth prompts | HTTP/REST (assumed) |
| Third-Party Enrichment (device fingerprinting, IP geo) | Provides risk signals at ingestion | Vendor API — likely synchronous, blocking |
| Regulatory Reporting (RBI, FIU-IND) | Outbound compliance reports | Manual/batch file generation (no live API implied) |

## 4. Architectural Pain Points (Why We're Re-Architecting)

| # | Pain Point | Business Impact |
|---|---|---|
| 1 | **Single Oracle database bottleneck** | All capabilities share one DB → no independent scaling, 3-second analytical queries, single point of failure with no replicas. |
| 2 | **Batch ML scoring (15-min cycle)** | Directly exploited by fraudsters in Q3 2025 — a 10-20 transaction fraud window opens after every batch run. |
| 3 | **Hardcoded rules in Java switch statements** | Any rule change needs a full code deployment inside a 4-hour weekly maintenance window — far too slow to respond to emerging fraud patterns. |
| 4 | **No graph/relationship analysis** | Organised fraud rings (e.g., the AI-generated synthetic identity ring) are invisible to rule + batch-ML detection alone. |
| 5 | **Manual, infrequent deployments** | Weekly Saturday-night window means even *urgent* fixes queue for days. |
| 6 | **Tight coupling across capabilities** | A bug or load spike in, say, Case Management code could in principle affect the Transaction Ingestion path, since everything runs in one process. |
| 7 | **No service-level observability** | A single monolith makes it hard to see *which* capability is slow/failing — contributing to the kind of detection-and-response delay seen in the Target breach case study (Part C1). |

## 5. Implication for Target Architecture

Each pain point above maps directly to a microservices principle we'll apply on Day 2:
- Pain #1 → **decentralised data ownership** (each service gets its own datastore)
- Pain #2 → **real-time event-driven scoring** instead of batch (Kafka + streaming inference)
- Pain #3 → **externalised, versioned rule configuration** (YAML/JSON-driven rule engine, Day 7)
- Pain #4 → **new Graph Analysis bounded context** (Day 9)
- Pain #5 → **independent deployability + CI/CD per service** (Day 14)
- Pain #6 → **bounded contexts with clear API/event boundaries** (Day 2)
- Pain #7 → **per-service observability** (Days 12-13)
