# Structured Logging Standard

**Day 13 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 11 July 2026

---

## Format: Structured JSON

Every log line across every service is a single-line JSON object.
No multi-line logs, no plain-text logs, no custom formats.
Reason: Fluentd/Fluent Bit can reliably parse JSON in a single pass;
plain-text logs require fragile regex patterns that break on edge cases.

---

## Mandatory Fields (every log line, every service)

```json
{
  "timestamp":    "2026-07-11T10:23:45.123Z",
  "level":        "INFO",
  "service":      "rule-engine-svc",
  "version":      "v2.14.1",
  "instance_id":  "rule-engine-svc-7d9f8b-xk2p4",
  "trace_id":     "4bf92f3577b34da6a3ce929d0e0e4736",
  "span_id":      "00f067aa0ba902b7",
  "message":      "Rule evaluation completed",
  "environment":  "production",
  "region":       "ap-south-1"
}
```

| Field | Type | Description | Source |
|---|---|---|---|
| `timestamp` | ISO 8601 UTC | Log event time | Application |
| `level` | ENUM: DEBUG/INFO/WARN/ERROR/FATAL | Log severity | Application |
| `service` | String | Service name (matches Kubernetes pod label) | Injected by Fluentd |
| `version` | String | Deployed image tag | Injected from env var IMAGE_TAG |
| `instance_id` | String | Pod name | Injected from env var POD_NAME |
| `trace_id` | String | OpenTelemetry trace ID — same across all services for one transaction | Propagated via W3C TraceContext header |
| `span_id` | String | OpenTelemetry span ID for this specific log entry | Current span |
| `message` | String | Human-readable description | Application |
| `environment` | String | production / staging / development | Injected from env var ENVIRONMENT |
| `region` | String | Cloud region | Injected from env var REGION |

---

## Optional Context Fields (include when relevant)

```json
{
  "transaction_id":  "txn_01HX9K2P3Q4R5S6T7U8V",
  "card_hash":       "a3f8c2d1e4b5...",
  "merchant_id":     "merch_MUM_001",
  "risk_action":     "AUTO_DECLINE",
  "composite_score": 847,
  "rule_id":         "rule_V001",
  "duration_ms":     23,
  "error_code":      "RULE_TIMEOUT",
  "error_detail":    "Rule evaluation exceeded 50ms budget",
  "http_status":     200,
  "http_method":     "POST",
  "http_path":       "/api/v1/transactions",
  "kafka_topic":     "fraud.transactions.enriched",
  "kafka_partition": 12,
  "kafka_offset":    4829301
}
```

---

## PII Masking Rules (PCI DSS Requirement + GDPR)

The following fields are **never** logged in plain text under any circumstances:

| Data | Rule | What to log instead |
|---|---|---|
| PAN (card number) | NEVER log | `card_hash` (SHA-256) |
| CVV / CVC | NEVER log | Omit entirely |
| Cardholder name | NEVER log | `customer_hash` |
| Full IP address | Mask last octet | `192.168.1.xxx` |
| Phone number | NEVER log | `phone_hash` |
| Email address | NEVER log | `email_hash` |
| OTP / PIN | NEVER log | Omit entirely |
| Bank account number | NEVER log | `account_hash` |

PII masking is enforced at the logging library level (custom log formatter),
not by developer discipline — developers cannot accidentally log a raw PAN
because the PAN type in the codebase has a custom `toString()` that returns
the hash, not the raw value.

---

## Log Levels — Usage Guide

| Level | When to use | Example |
|---|---|---|
| `DEBUG` | Detailed execution flow — disabled in production by default | "Evaluating rule V001 against condition: txn_count_10m=7" |
| `INFO` | Normal business events — enabled in production | "Transaction auto-approved, score=145" |
| `WARN` | Degraded but not broken — enabled in production | "Graph analysis timed out, proceeding without graph signal" |
| `ERROR` | Something failed that should not — enabled in production | "Redis feature store unavailable, using population averages" |
| `FATAL` | Service cannot continue — enabled in production | "Rule cache empty after startup — cannot evaluate transactions" |

`DEBUG` logs are disabled in production by default. They can be enabled
per-service for up to 30 minutes via a feature flag (ConfigMap update),
after which they auto-disable. This prevents debug log storms in production.

---

## Log Retention Policy

| Environment | Retention | Storage |
|---|---|---|
| Production | 90 days hot (Elasticsearch), then 7 years cold (S3 Glacier) | Elasticsearch + S3 |
| Staging | 30 days | Elasticsearch |
| Development | 7 days | Elasticsearch |

7-year cold retention satisfies RBI audit requirements.
Elasticsearch 90-day hot retention covers all operational investigation windows.

---

## Log Pipeline

```
Application (JSON to stdout)
  → Fluent Bit (DaemonSet on each node, collects from container stdout)
    → Enriches with: service, version, instance_id, environment, region
    → Filters: drops health-check logs (/healthz, /metrics) to reduce noise
    → Routes: production logs → Elasticsearch cluster
              error-level logs → also forwarded to PagerDuty webhook
  → Elasticsearch (indexed by timestamp, trace_id, service, level)
    → Kibana (visualisation and search)
```

**Kibana index pattern:** `fraud-logs-{YYYY.MM.DD}`
**Key Kibana saved searches:**
- All ERROR logs in last 1 hour by service
- All logs for a given `trace_id` (end-to-end transaction trace)
- All `WARN` logs mentioning "timed out" or "fallback"
