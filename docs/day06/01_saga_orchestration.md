# Saga Orchestration Diagrams

**Day 6 Deliverable | SWE-2C Fraud Detection Microservices Architecture**
**Author:** Aditi Sharma | **Date:** 3 July 2026

> A Saga is a sequence of local transactions where each step publishes an event
> to trigger the next step. If any step fails, compensating transactions undo
> the preceding steps. No two-phase commit — each service only touches its own data.
>
> Orchestration pattern (a central Saga Orchestrator directs all participants) is
> used for complex multi-service workflows like fraud investigation, where partial
> failures have legal/compliance implications and need explicit rollback logic.

---

## Saga 1: Transaction Processing Saga

**Trigger:** `TransactionSubmitted`
**Success end state:** `TransactionAutoApproved` / `StepUpAuthRequested` /
`TransactionFlaggedForReview` / `TransactionAutoDeclined`

```mermaid
sequenceDiagram
    participant CH as Payment Channel
    participant TI as transaction-ingestion-svc
    participant RE as rule-engine-svc
    participant AD as anomaly-detection-svc
    participant GA as graph-analysis-svc
    participant RS as risk-scoring-svc
    participant NO as notification-svc
    participant AU as audit-compliance-svc

    CH->>TI: SubmitTransaction (REST)
    TI->>TI: Validate + Enrich
    TI->>RE: publish fraud.transactions.enriched
    TI->>AD: publish fraud.transactions.enriched
    TI->>GA: publish fraud.transactions.enriched

    par Parallel detection (all 3 run simultaneously)
        RE->>RS: publish fraud.rule.results
    and
        AD->>RS: publish fraud.anomaly.scores
    and
        GA->>RS: publish fraud.graph.signals
    end

    Note over RS: Signal Correlator waits up to 80ms
    RS->>RS: ComputeScore + BuildExplanation
    RS->>NO: publish notifications.outbound
    RS->>AU: publish fraud.audit.events
    RS->>CH: RiskDecision (AUTO_APPROVE / STEP_UP / REVIEW / DECLINE)

    Note over RS,AU: If graph timed out: score computed with Rule+ML only,<br/>+100 point safety margin applied, graph_available=false logged to audit
```

**Compensating transactions (failure scenarios):**

| Step | Failure | Compensating Action |
|---|---|---|
| Enrichment times out | External API unavailable | Proceed with partial enrichment, flag `enrichment_partial=true` in audit |
| Rule Engine times out | Service unavailable | Skip rule score, fallback to ML+Graph only, lower approval threshold |
| Anomaly Detection times out | Service/feature store unavailable | Skip ML score, use population-average features in explanation |
| Graph Analysis times out | Neo4j unavailable | Skip graph score, add +100 safety margin, log `graph_skipped=true` |
| Risk Scoring fails | Internal error | Return 503 to channel; transaction not processed; no money moved |

---

## Saga 2: Fraud Investigation Saga

**Trigger:** `TransactionFlaggedForReview` (score 600-799)
**Success end states:** `FraudConfirmed` → chargeback + card block, OR `FalsePositiveConfirmed` → transaction approved

```mermaid
sequenceDiagram
    participant RS as risk-scoring-svc
    participant CM as case-management-svc
    participant CARD as card-management (logical)
    participant NO as notification-svc
    participant AU as audit-compliance-svc

    RS->>CM: publish fraud.risk.decisions (action=MANUAL_REVIEW)
    CM->>CM: CreateCase + AssignAnalyst (round-robin / priority queue)
    CM->>NO: publish notifications.outbound (notify analyst via Slack/PagerDuty)
    CM->>CARD: FreezeCard (compensating: UnfreezeCard)
    NO->>NO: SendNotification to analyst

    Note over CM: Analyst investigates within 4-hour SLA

    alt Fraud Confirmed
        CM->>CM: RecordDecision(CONFIRMED_FRAUD)
        CM->>CARD: BlockCardPermanently (compensating: N/A — irreversible after confirmation)
        CM->>NO: NotifyCardholder(fraud_confirmed)
        CM->>CM: InitiateChargeback
        CM->>AU: publish fraud.audit.events (case_decision)
        CM->>CM: CloseCase
    else False Positive
        CM->>CM: RecordDecision(FALSE_POSITIVE)
        CM->>CARD: UnfreezeCard
        CM->>NO: NotifyCardholder(apology + explanation)
        CM->>AU: publish fraud.audit.events (false_positive_recorded)
        CM->>CM: CloseCase + UpdateFPMetrics
    else SLA Breached (no decision in 4h)
        CM->>CM: EscalateCase to senior analyst
        CM->>NO: NotifyManager(sla_breach)
    end
```

**Compensating transactions:**

| Step | Failure | Compensating Action |
|---|---|---|
| `FreezeCard` fails | card-management unavailable | Log failure to audit; case created anyway; analyst manually freezes |
| `NotifyAnalyst` fails | notification-svc down | Notification queued in Kafka DLQ; retried on recovery |
| `BlockCardPermanently` issued in error | Wrong case resolved as fraud | Requires dual-authorisation reversal — logged as AuditEventType.CONFIG_CHANGE |

---

## Saga 3: Card Blocking Saga

**Trigger:** `FraudConfirmed` from Fraud Investigation Saga

```mermaid
sequenceDiagram
    participant CM as case-management-svc
    participant CARD as card-management (logical)
    participant NO as notification-svc
    participant AU as audit-compliance-svc
    participant CP as customer-profile-svc

    CM->>CARD: BlockCardPermanently
    CARD->>AU: publish audit.events (card_blocked)
    CARD->>NO: publish notifications.outbound (card_blocked alert to cardholder)
    NO->>NO: SendNotification (SMS + email + push)
    CARD->>CARD: IssueReplacementCard
    CARD->>NO: publish notifications.outbound (replacement_card_issued)
    NO->>NO: SendNotification (replacement card details via secure channel)
    CM->>CP: UpdateCustomerProfile (mark account as fraud-victim, reset risk tier)
    CP->>AU: publish audit.events (profile_updated)
```

---

## CQRS Read Models for Analytics Dashboard

CQRS (Command Query Responsibility Segregation) separates the write path (transaction
detection pipeline, strong consistency) from the read path (analytics, eventual
consistency). Read models are materialised views, updated by Kafka Streams consumers.

| Read Model | Source Topics | Update Frequency | Storage | Consumer |
|---|---|---|---|---|
| Real-time fraud statistics | `fraud.risk.decisions` | Per event (<1s lag) | TimescaleDB | `analytics-streams-cg` |
| Geographic heat map | `fraud.risk.decisions` | Every 60 seconds (windowed) | TimescaleDB | `geo-aggregator-cg` |
| Rule effectiveness metrics | `fraud.rule.results` | Per event | TimescaleDB | `rule-metrics-cg` |
| ML model performance | `fraud.anomaly.scores` + chargeback data | Daily (chargeback lag 30-90 days) | PostgreSQL | `model-monitor-cg` |
| Case management backlog | `fraud.risk.decisions` + case events | Per event | PostgreSQL | `case-analytics-cg` |

### Kafka Streams topology (real-time fraud statistics read model)

```
Source: fraud.risk.decisions
  → Filter: valid RiskDecision events
  → GroupBy: channel, hour_bucket (tumbling window 1h)
  → Aggregate: count(AUTO_APPROVE), count(AUTO_DECLINE),
               count(STEP_UP_AUTH), count(MANUAL_REVIEW),
               avg(composite_score)
  → Sink: TimescaleDB table `fraud_stats_hourly`
            → served by analytics REST API → Grafana dashboard
```
