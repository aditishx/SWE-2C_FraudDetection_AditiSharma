# Data Encryption Strategy

**Day 10 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 8 July 2026

---

## Encryption at Rest — AES-256 (PCI DSS Requirement 3)

| Data store | Encryption | Key management |
|---|---|---|
| PostgreSQL (all instances) | AES-256 via Transparent Data Encryption (TDE) | Keys stored in HashiCorp Vault, rotated every 90 days |
| Redis (feature store, rule cache) | AES-256 at disk level (Redis Enterprise) | Keys stored in HashiCorp Vault |
| Neo4j (property graph) | AES-256 via Neo4j Enterprise encryption at rest | Keys stored in HashiCorp Vault |
| Cassandra (customer profiles) | AES-256 via Cassandra encryption at rest | Keys stored in HashiCorp Vault |
| Kafka (all topics) | AES-256 via Confluent Platform encryption at rest | Keys stored in HashiCorp Vault |
| S3/GCS (archived graph data, audit cold storage) | AES-256 SSE (server-side encryption) | AWS KMS / GCP KMS |

## Encryption in Transit — mTLS (PCI DSS Requirement 4)

| Connection | Protocol | Certificate authority |
|---|---|---|
| External client → API Gateway | TLS 1.3 (minimum) | Public CA (Let's Encrypt / DigiCert) |
| API Gateway → internal services | mTLS via Istio | Istio internal CA (self-signed, rotated every 24h) |
| Service → service (all internal) | mTLS via Istio sidecar | Istio internal CA |
| Service → PostgreSQL | TLS 1.3 | Internal CA (HashiCorp Vault PKI) |
| Service → Redis | TLS 1.3 | Internal CA |
| Service → Neo4j | TLS 1.3 (Bolt protocol) | Internal CA |
| Service → Kafka | TLS 1.3 + SASL/SCRAM | Internal CA |

## PAN Tokenisation (PCI DSS Requirement 3.5)

Raw card numbers (PANs) are never stored anywhere in the new architecture.
Tokenisation happens at the very first point of entry — the payment channel
sends a token (issued by the card network's tokenisation service) rather
than the raw PAN.

```
Payment Channel
  → sends: card_token (issued by Visa/Mastercard/RuPay tokenisation service)
  → transaction-ingestion-svc: hashes token to card_number_hash (SHA-256)
  → card_number_hash is the only identifier used throughout the entire platform
  → raw PAN never stored, never transmitted internally
```

This satisfies RBI's tokenisation mandate (effective October 2022) and
eliminates the primary PCI DSS scope concern for stored cardholder data.

## Key Rotation Policy

| Key type | Rotation frequency | Mechanism |
|---|---|---|
| Istio service certificates | Every 24 hours | Automatic via Istio CA |
| Database encryption keys | Every 90 days | HashiCorp Vault auto-rotate + re-encrypt |
| Kafka SASL credentials | Every 30 days | Vault dynamic secrets |
| API Gateway JWT signing key (RS256) | Every 30 days | Vault PKI, JWKS endpoint updated automatically |
| External TLS certificates | Before expiry (auto-renew via cert-manager) | Let's Encrypt / ACME protocol |

Key rotation is fully automated — no manual steps, no maintenance windows required.
