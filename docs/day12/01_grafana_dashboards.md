# Grafana Dashboard Specifications

**Day 12 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 10 July 2026

> Four dashboards covering the complete operational picture.
> All dashboards use recording rules from prometheus_rules.yaml for fast load times.
> Refresh rate: 15s for real-time dashboards, 1m for case management.

---

## Dashboard 1 — Transaction Processing

**Audience:** Platform engineers, on-call SRE
**Purpose:** Real-time health of the critical transaction path

### Panels

| Panel | Type | Query | Alert threshold |
|---|---|---|---|
| Transactions/second (live) | Stat + sparkline | `fraud:transaction_rate:1m` | Red if <100 TPS |
| p50 / p95 / p99 pipeline latency | Gauge × 3 | `fraud:pipeline_latency_p50/p95/p99:5m` | p99 red >200ms |
| Decision distribution (pie) | Pie chart | `fraud:decision_rate:*:5m` per action type | — |
| Kafka consumer lag (critical path) | Time series | `fraud:kafka_lag_max:critical_path` | Red >1000 |
| Per-service error rate | Table | `fraud:service_error_rate:5m` by service | Red >0.01 |
| Active alerts (P1 + P2) | Alert list | All firing alerts | — |
| Transaction volume heatmap (by hour, by channel) | Heatmap | `sum by (hour, channel) (fraud_decisions_total)` | — |
| Gateway rate limit hits | Time series | `kong_http_status{status="429"}` | — |

---

## Dashboard 2 — Fraud Detection

**Audience:** Fraud Ops team, CRO, Fraud Manager
**Purpose:** Detection effectiveness and fraud pattern visibility

### Panels

| Panel | Type | Query | Alert threshold |
|---|---|---|---|
| Fraud detection rate (7-day rolling) | Stat | `fraud_confirmed_total / fraud_decisions_total{action=~"AUTO_DECLINE|MANUAL_REVIEW"}` | Red <95% |
| False positive rate (7-day rolling) | Stat | `fraud_false_positive_total / fraud_decisions_total{action=~"STEP_UP_AUTH|MANUAL_REVIEW"}` | Red >0.5% |
| Rule trigger frequency (top 10) | Bar chart | `topk(10, rate(rule_trigger_total[1h]))` | — |
| Rule false positive rate per rule | Table | `rule_fp_rate by (rule_id, rule_name)` | Red >1% |
| ML model score distribution | Histogram | `histogram_quantile(*, ml_score_bucket)` | — |
| Graph analysis hit rate | Stat | `rate(graph_fraud_topology_matched_total[1h])` | — |
| Geographic fraud heat map | Geo map | `fraud_decisions_total{action="AUTO_DECLINE"} by (country)` | — |
| Fraud amount by channel (stacked bar) | Bar chart | `fraud_amount_total by (channel)` | — |
| DLQ message counts per topic | Time series | `kafka_consumer_lag{topic=~"*.dlq"}` | Red >100 |

---

## Dashboard 3 — Case Management

**Audience:** Fraud analysts, Case management team, Head of Compliance
**Purpose:** Analyst workload and SLA compliance tracking

### Panels

| Panel | Type | Query | Alert threshold |
|---|---|---|---|
| Open cases total | Stat | `fraud_cases_total{status="OPEN"}` | — |
| Cases breaching 4-hour SLA | Stat | `fraud_cases_total{status="OPEN", age_hours > 4}` | Red >0 |
| Average case resolution time (hours) | Stat | `avg(fraud_case_resolution_hours)` | — |
| Cases by status (donut) | Donut chart | `fraud_cases_total by (status)` | — |
| Cases per analyst (workload) | Bar chart | `fraud_cases_total{status="OPEN"} by (assigned_analyst)` | — |
| Case volume trend (7 days) | Time series | `rate(fraud_cases_created_total[1d])` | — |
| Confirmed fraud vs false positive (7d) | Stacked bar | `fraud_case_decisions_total by (outcome, day)` | — |
| Chargeback initiation rate | Stat | `fraud_chargebacks_total / fraud_cases_total{outcome="CONFIRMED_FRAUD"}` | — |

---

## Dashboard 4 — Infrastructure

**Audience:** Platform engineers, SRE team
**Purpose:** Kubernetes, database, and Kafka infrastructure health

### Panels

| Panel | Type | Query | Alert threshold |
|---|---|---|---|
| CPU usage per service | Time series | `rate(container_cpu_usage_seconds_total[5m]) by (pod)` | Red >80% |
| Memory usage per service | Time series | `container_memory_working_set_bytes by (pod)` | Red >85% |
| Pod restarts (last 1h) | Table | `kube_pod_container_status_restarts_total` | Red >2 |
| HPA scaling events | Time series | `kube_horizontalpodautoscaler_status_current_replicas by (hpa)` | — |
| Neo4j query latency (p99) | Gauge | `histogram_quantile(0.99, neo4j_query_duration_seconds_bucket)` | Red >50ms |
| Redis cache hit rate | Stat | `redis_hit_rate` | Red <90% |
| Kafka broker health | Table | `kafka_broker_count`, `kafka_under_replicated_partitions` | Red if partitions under-replicated |
| PostgreSQL connection pool usage | Time series | `pg_pool_connections_used / pg_pool_connections_max` | Red >80% |
| Estimated infra cost/hour | Stat | `infra_estimated_hourly_cost_usd` | — |

---

## Alert Routing Configuration

```yaml
# Alertmanager routing config
route:
  group_by: [alertname, severity]
  group_wait: 30s
  group_interval: 5m
  repeat_interval: 1h
  receiver: default-slack

  routes:
    # P1 — PagerDuty, auto-escalate after 5 minutes
    - match:
        severity: P1
      receiver: pagerduty-p1
      continue: true
      repeat_interval: 5m

    # P2 — Slack #alerts channel, escalate after 30 minutes
    - match:
        severity: P2
      receiver: slack-alerts
      repeat_interval: 30m

    # P3 — Daily digest email
    - match:
        severity: P3
      receiver: email-daily-digest
      group_wait: 6h
      group_interval: 24h
      repeat_interval: 24h

    # P4 — Weekly review dashboard (no active notification)
    - match:
        severity: P4
      receiver: email-weekly-digest
      group_wait: 24h
      group_interval: 168h
      repeat_interval: 168h

receivers:
  - name: pagerduty-p1
    pagerduty_configs:
      - service_key: "<vault:pagerduty/service-key>"
        severity: critical
        description: "{{ .CommonAnnotations.summary }}"
        details:
          runbook: "{{ .CommonAnnotations.runbook }}"

  - name: slack-alerts
    slack_configs:
      - api_url: "<vault:slack/webhook-url>"
        channel: "#fraud-platform-alerts"
        title: "[{{ .Status | toUpper }}] {{ .CommonAnnotations.summary }}"
        text: "{{ .CommonAnnotations.description }}"
        color: '{{ if eq .Status "firing" }}danger{{ else }}good{{ end }}'

  - name: email-daily-digest
    email_configs:
      - to: fraud-ops@shieldpay.in
        subject: "[P3 Daily Digest] {{ .CommonAnnotations.summary }}"

  - name: email-weekly-digest
    email_configs:
      - to: platform-leads@shieldpay.in
        subject: "[P4 Weekly] Infrastructure & Cost Review"
