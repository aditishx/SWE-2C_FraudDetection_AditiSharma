# C4 Level 1 — System Context Diagram

**Day 2 Deliverable | SWE-2C Fraud Detection Microservices Architecture**

## What is C4 Level 1?

Per Section A1.3, Level 1 (System Context) treats the **entire fraud detection
platform as a single black box** and shows only: who/what talks to it, in which
direction, and over what protocol. No internal services are shown yet — that's
Level 2 (Container), which we start drafting below.

## Diagram

```mermaid
flowchart TB
    subgraph ext_top[" "]
        direction LR
        CARD["Card Payment Networks<br/>(Visa, Mastercard, RuPay)"]
        CBS["Core Banking System<br/>(balance, account status)"]
        ENRICH["Third-Party Enrichment<br/>(ThreatMetrix, MaxMind, velocity data)"]
    end

    PLATFORM["🛡️ ShieldPay Fraud Detection Platform<br/><br/>Analyses transactions in real time using<br/>rule engines, ML anomaly detection, and<br/>graph-based relationship analysis.<br/>Produces explainable, auditable decisions."]

    subgraph ext_bottom[" "]
        direction LR
        MOBILE["Customer Mobile App<br/>(notifications, step-up auth)"]
        REG["Regulatory Reporting<br/>(RBI, FIU-IND, PCI DSS assessors)"]
        LEGACY["Legacy Monolith System<br/>(during migration period)"]
    end

    CARD -->|"Transaction auth requests<br/>(ISO 8583 / REST, sync)"| PLATFORM
    PLATFORM -->|"Approve / Decline / Step-up<br/>(sync response)"| CARD

    PLATFORM -->|"Balance/account lookup<br/>(gRPC, sync)"| CBS
    CBS -->|"Account status response"| PLATFORM

    ENRICH -->|"Device fingerprint, IP geo,<br/>velocity signals (REST, sync)"| PLATFORM

    PLATFORM -->|"Push notification, step-up<br/>challenge (REST/webhook, async)"| MOBILE
    MOBILE -->|"OTP / biometric response"| PLATFORM

    PLATFORM -->|"Fraud reports, STR filings,<br/>audit evidence (batch/API)"| REG

    LEGACY <-->|"Anti-Corruption Layer<br/>(REST adapter, sync, migration-only)"| PLATFORM

    classDef platform fill:#185FA5,stroke:#0B3A66,color:#FFFFFF,font-weight:bold
    classDef external fill:#CECBF6,stroke:#534AB7,color:#26215C
    class PLATFORM platform
    class CARD,CBS,ENRICH,MOBILE,REG,LEGACY external
```

## External System Inventory

| External System | Direction | Protocol | Notes |
|---|---|---|---|
| **Card Payment Networks** (Visa, Mastercard, RuPay) | Bidirectional | ISO 8583 / REST, synchronous | The platform must respond within the latency SLA (Auto-Approve/Decline: <100ms) since the network is waiting on the response to forward to the merchant |
| **Core Banking System** | Bidirectional, sync | gRPC | Provides real-time balance/account status; critical-path dependency for some decisions |
| **Customer Mobile Application** | Bidirectional, async | REST/webhook for outbound; REST inbound for OTP/biometric response | Enables step-up authentication flow (score 200-599 band) |
| **Third-Party Enrichment Services** (ThreatMetrix-style device FP, MaxMind-style IP geo, velocity providers) | Inbound to platform, sync | REST | Consumed during Transaction Ingestion's enrichment step |
| **Regulatory Reporting Systems** (RBI, FIU-IND, PCI DSS assessors) | Outbound, mixed sync/batch | API + batch file | STR filings, fraud reporting above 2 lakh INR threshold, audit evidence retrieval |
| **Legacy Monolith System** | Bidirectional, sync, **migration-period only** | REST via Anti-Corruption Layer | Retired incrementally per the Strangler Fig pattern (Section A1.1) — this integration point should shrink to zero over time, not grow |

## Design note: why no internal services appear here

This is intentional, and it's the entire point of C4 Level 1 — stakeholders like the
CFO or Head of Compliance (Section B1.3) need to understand *what the platform does
and who it talks to* without being shown 10 microservices and 5 databases. That level
of detail comes next, in C4 Level 2.
