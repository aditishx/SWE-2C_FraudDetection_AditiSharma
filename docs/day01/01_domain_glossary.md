# Domain Glossary — Real-Time Fraud Detection

**Day 1 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 28 June 2026

> Purpose: A shared vocabulary ("ubiquitous language" in DDD terms) for every term used
> across this project. Anyone — engineer, risk officer, auditor — should be able to read
> this and understand exactly what each term means in *our* system.

---

## A. Payment & Card Fundamentals

| Term | Definition |
|---|---|
| **PAN** | Primary Account Number — the 16-digit card number. Never stored raw; always tokenised or hashed in our system. |
| **BIN** | Bank Identification Number — first 6-8 digits of a PAN, identifying the issuing bank/network. Used to route transactions and assess issuer-level risk. |
| **MCC** | Merchant Category Code — a 4-digit code classifying the merchant's business type (e.g., 7995 = gambling, 6051 = cryptocurrency). Key input to rule-based detection. |
| **CVV/CVC** | Card Verification Value — the 3-4 digit security code, used as proof of physical card possession in CNP transactions. |
| **EMV** | Chip-based card standard that reduced counterfeit (cloned) card fraud at physical terminals. |
| **AFA** | Additional Factor of Authentication — RBI-mandated second factor (typically OTP) for online card transactions in India. |
| **Tokenisation** | Replacing a stored PAN with a non-reversible token, mandated by RBI (effective Oct 2022) for merchant card-on-file storage. |
| **UPI** | Unified Payments Interface — India's real-time bank-to-bank payment rail; processes 10B+ transactions/month and has its own fraud patterns (QR phishing, fake collect requests). |
| **RuPay** | India's domestic card network (alternative to Visa/Mastercard) with its own BIN ranges. |

## B. Fraud Types

| Term | Definition |
|---|---|
| **CP Fraud** | Card-Present fraud — physical card/clone used at a POS terminal (skimming, lost/stolen card). |
| **CNP Fraud** | Card-Not-Present fraud — no physical card involved (e-commerce, mobile, MOTO). ~75% of global card fraud. |
| **ATO** | Account Takeover — fraudster gains control of a legitimate account using stolen credentials. |
| **Enumeration Attack** | Automated testing of many stolen card numbers with small transactions to find which ones are still valid. |
| **Friendly Fraud** | A legitimate cardholder disputes a real transaction to get a refund (a.k.a. first-party/chargeback fraud). |
| **Triangulation Fraud** | Fraudster sells goods cheaply, buys them with a stolen card, ships directly to the real buyer — hiding the theft inside an apparently normal sale. |
| **Synthetic Identity Fraud** | A fabricated identity (real + fake personal data combined) used to open and build credit on an account that doesn't correspond to a real person. |
| **SIM-Swap Fraud** | Attacker hijacks a victim's phone number to intercept OTPs (relevant to AFA security). |
| **Money Mule** | An account/person used to move fraudulently obtained funds, often unknowingly, between accounts to obscure the money trail. |

## C. Detection Techniques

| Term | Definition |
|---|---|
| **Rule Engine** | A deterministic system evaluating transactions against pre-defined conditional rules (e.g., velocity, amount thresholds). Fast, explainable, but only catches *known* patterns. |
| **Velocity Rule** | A rule based on frequency over time, e.g., ">5 transactions in 10 minutes." |
| **Anomaly Detection** | ML-based technique to flag transactions that deviate from learned normal behaviour — catches *unknown* or evolving fraud patterns. |
| **Supervised Model** | ML model trained on labelled fraud/not-fraud historical data (e.g., XGBoost, logistic regression). |
| **Unsupervised Model** | ML model that detects anomalies without labels (e.g., isolation forest, autoencoder). |
| **Feature Engineering** | The process of deriving model inputs (e.g., "transactions in last 10 minutes") from raw transaction data. |
| **Graph Analysis** | Detection technique modelling entities (cards, devices, accounts) as nodes and relationships as edges, to uncover organised fraud rings invisible to rules/ML alone. |
| **Community Detection** | Graph algorithm (e.g., Louvain) that finds clusters of densely-connected entities — a possible fraud ring signature. |
| **Risk Score** | The composite 0-1000 output combining rule, ML, and graph signals, used to decide the transaction's fate. |
| **Explainability** | The requirement that every automated decision can be traced back to the specific signals that caused it (regulatory requirement). |

## D. Metrics & Performance

| Term | Definition |
|---|---|
| **False Positive Rate (FPR)** | % of *legitimate* transactions incorrectly flagged as fraud. High FPR = angry customers. |
| **Detection Rate / Recall** | % of *actual* fraud correctly caught by the system. |
| **Precision** | Of everything flagged as fraud, what % actually was fraud. |
| **Chargeback** | A forced transaction reversal initiated by the cardholder's bank, often following a fraud dispute. |
| **SLA** | Service Level Agreement — a measurable commitment (e.g., "p99 latency < 200ms"). |
| **RPO** | Recovery Point Objective — max acceptable data loss in a disaster, measured in time. |
| **RTO** | Recovery Time Objective — max acceptable downtime in a disaster. |

## E. Architecture & Engineering Terms

| Term | Definition |
|---|---|
| **Microservice** | An independently deployable service owning one business capability and its own data. |
| **Monolith** | A single deployable unit containing all logic — ShieldPay's current legacy system. |
| **Bounded Context** | A DDD concept: a boundary within which a particular business model/vocabulary is consistent and self-contained. |
| **Event-Driven Architecture (EDA)** | A design style where services communicate by publishing/consuming events rather than direct calls. |
| **Kafka Topic** | A named, ordered, durable stream of events in Apache Kafka — our event backbone. |
| **gRPC** | A high-performance binary RPC framework used for internal service-to-service calls requiring low latency. |
| **Saga** | A pattern for managing a multi-step business transaction across services without a distributed transaction/lock. |
| **CQRS** | Command Query Responsibility Segregation — separating the "write" model from the "read" model for performance/scalability. |
| **Circuit Breaker** | A resilience pattern that stops calling a failing downstream service temporarily, to prevent cascading failure. |
| **Service Mesh** | Infrastructure layer (e.g., Istio) handling service-to-service security, traffic, and observability outside application code. |
| **mTLS** | Mutual TLS — both client and server verify each other's identity cryptographically; used for zero-trust internal communication. |
| **Idempotency** | A property where processing the same request/event twice has the same effect as processing it once — critical for safe retries in distributed systems. |

## F. Regulatory & Compliance

| Term | Definition |
|---|---|
| **RBI** | Reserve Bank of India — India's central bank and the primary financial regulator for this platform. |
| **PCI DSS** | Payment Card Industry Data Security Standard — global mandatory security standard for anyone storing/processing card data. |
| **FIU-IND** | Financial Intelligence Unit, India — receives Suspicious Transaction Reports (STRs). |
| **STR** | Suspicious Transaction Report — a mandatory filing when fraud/suspicious activity crosses a threshold. |
| **GDPR** | EU's General Data Protection Regulation — applies if the platform serves European cardholders; conflicts in places with RBI's retention rules. |
| **Audit Trail** | An immutable record of every decision and change in the system, required for regulatory examination. |

---